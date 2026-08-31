#!/usr/bin/env python3
"""Кинематик жазудың clipper демоны.

Екі режим:

  python clipper.py watch --out markers.json --duration 420
      Roblox клиент логын "tail" етіп, __BFA_HIGHLIGHT__ маркерлерін жинайды.
      --duration біткенде немесе Ctrl+C-де жиналғанды --out файлына жазып шығады.

  python clipper.py cut --recording REC.mp4 --markers markers.json \
      --session-start <epoch_ms> --repo "D:/Blox Fight Arena" [--push]
      Әр маркердің айналасынан ffmpeg-пен вертикаль клип кесіп,
      automation/upload/clips/ ішіне қояды, қаласаң git push жасайды.

Roblox серверде HttpService жазушы машинаға localhost арқылы жете алмайтындықтан,
highlight сигналдары клиент логы арқылы өтеді (CinematicMarkers.lua қараңыз).
"""

import argparse
import json
import os
import re
import signal
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

MARKER = "__BFA_HIGHLIGHT__"

# Клип терезесі (сек). Логты "tail" ету кідірісін жабу үшін PRE үлкенірек.
PRE_SECONDS = 12
POST_SECONDS = 8
MERGE_GAP = 8          # осыдан жақын маркерлер бір клипке біріктіріледі
MAX_CLIP_SECONDS = 45

# Highlight түрін файл атына жарайтын ASCII тегке аудару.
TYPE_TAGS = {
    "Алғашқы қан": "First Blood",
    "Кек": "Revenge",
    "Killstreak": "Killstreak",
    "Дубль": "Double Kill",
    "Өлтіру": "Kill",
    "Boss жеңілді": "Boss Down",
}

LOG_TS_RE = re.compile(r"^(\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(?:\.\d+)?Z?)")


def roblox_logs_dir() -> Path:
    return Path(os.environ["LOCALAPPDATA"]) / "Roblox" / "logs"


def parse_log_ts(line: str) -> float | None:
    m = LOG_TS_RE.match(line.strip())
    if not m:
        return None
    raw = m.group(1).replace(" ", "T")
    try:
        if raw.endswith("Z"):
            dt = datetime.strptime(raw, "%Y-%m-%dT%H:%M:%S.%fZ") if "." in raw \
                else datetime.strptime(raw, "%Y-%m-%dT%H:%M:%SZ")
            return dt.replace(tzinfo=timezone.utc).timestamp()
        dt = datetime.strptime(raw, "%Y-%m-%dT%H:%M:%S.%f") if "." in raw \
            else datetime.strptime(raw, "%Y-%m-%dT%H:%M:%S")
        return dt.replace(tzinfo=timezone.utc).timestamp()
    except ValueError:
        return None


def newest_session_log(since: float) -> Path | None:
    logs = roblox_logs_dir()
    if not logs.is_dir():
        return None
    candidates = [
        p for p in logs.glob("*.log")
        if p.stat().st_mtime >= since - 10
    ]
    if not candidates:
        return None
    return max(candidates, key=lambda p: p.stat().st_mtime)


def cmd_watch(args: argparse.Namespace) -> int:
    started = time.time()
    deadline = started + args.duration if args.duration else None
    collected: list[dict] = []
    stop = {"flag": False}

    def _sig(_signum, _frame):
        stop["flag"] = True

    signal.signal(signal.SIGINT, _sig)
    signal.signal(signal.SIGTERM, _sig)

    print(f"[clipper] watch басталды (dur={args.duration}s) — лог күтілуде...")
    log_path: Path | None = None
    fh = None
    seen_lines = 0

    try:
        while not stop["flag"] and (deadline is None or time.time() < deadline):
            if fh is None:
                log_path = newest_session_log(started)
                if log_path:
                    fh = log_path.open("r", encoding="utf-8", errors="replace")
                    print(f"[clipper] лог: {log_path.name}")
                else:
                    time.sleep(1.0)
                    continue

            line = fh.readline()
            if not line:
                time.sleep(0.5)
                # Roblox кейде жаңа лог файлын ашады
                latest = newest_session_log(started)
                if latest and log_path and latest != log_path:
                    fh.close()
                    fh = log_path = None
                continue

            seen_lines += 1
            if MARKER not in line:
                continue

            payload = line.split(MARKER, 1)[1].strip()
            try:
                data = json.loads(payload)
            except json.JSONDecodeError:
                continue

            log_ts = parse_log_ts(line)
            wall = time.time()
            if log_ts and abs(log_ts - wall) > 120:
                log_ts = None

            entry = {
                "type": data.get("type", "?"),
                "description": data.get("description", ""),
                "at": log_ts or wall,
                "wall": wall,
            }
            collected.append(entry)
            print(f"[clipper] +highlight: {entry['type']} @ {entry['at']:.0f}")
    finally:
        if fh:
            fh.close()

    Path(args.out).write_text(
        json.dumps(collected, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(f"[clipper] watch аяқталды — {len(collected)} highlight → {args.out}")
    return 0


def merge_windows(offsets: list[float]) -> list[tuple[float, float]]:
    windows = sorted((max(0.0, o - PRE_SECONDS), o + POST_SECONDS) for o in offsets)
    merged: list[list[float]] = []
    for start, end in windows:
        if merged and start - merged[-1][1] <= MERGE_GAP:
            merged[-1][1] = max(merged[-1][1], end)
        else:
            merged.append([start, end])
    out = []
    for start, end in merged:
        end = min(end, start + MAX_CLIP_SECONDS)
        out.append((start, end))
    return out


def ffmpeg_cut(recording: Path, start: float, dur: float, out_path: Path) -> bool:
    vf = (
        "scale=1080:1920:force_original_aspect_ratio=decrease,"
        "pad=1080:1920:(ow-iw)/2:(oh-ih)/2:color=black,setsar=1,fps=30"
    )
    cmd = [
        "ffmpeg", "-y",
        "-ss", f"{start:.2f}", "-i", str(recording),
        "-t", f"{dur:.2f}",
        "-vf", vf,
        "-c:v", "libx264", "-preset", "veryfast", "-crf", "21",
        "-c:a", "aac", "-b:a", "128k",
        "-movflags", "+faststart",
        str(out_path),
    ]
    print(f"[clipper] ffmpeg: {out_path.name}  ({start:.1f}s +{dur:.1f}s)")
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(result.stderr[-1500:])
        return False
    return True


def cmd_cut(args: argparse.Namespace) -> int:
    recording = Path(args.recording)
    if not recording.is_file():
        print(f"[clipper] ҚАТЕ: жазба табылмады: {recording}")
        return 1

    markers = json.loads(Path(args.markers).read_text(encoding="utf-8"))
    if not markers:
        print("[clipper] highlight жоқ — клип кесілмейді.")
        return 0

    session_start = args.session_start / 1000.0
    offsets = []
    for m in markers:
        off = m["at"] - session_start
        if off >= 0:
            offsets.append(off)
    if not offsets:
        print("[clipper] жарамды offset жоқ.")
        return 0

    repo = Path(args.repo)
    clips_dir = repo / "automation" / "upload" / "clips"
    clips_dir.mkdir(parents=True, exist_ok=True)

    date_tag = datetime.now().strftime("%Y-%m-%d_%H%M%S")
    made: list[Path] = []
    for i, (start, end) in enumerate(merge_windows(offsets), 1):
        # Осы терезеге түсетін бірінші highlight түрін атқа қоямыз.
        wtype = "Highlight"
        for off, m in zip(offsets, markers):
            if start <= off <= end:
                wtype = TYPE_TAGS.get(m["type"], "Highlight")
                break
        name = f"Blox_Fight_Arena_{wtype.replace(' ', '_')}_{date_tag}_{i}.mp4"
        out_path = clips_dir / name
        if ffmpeg_cut(recording, start, end - start, out_path):
            made.append(out_path)

    if not made:
        print("[clipper] бірде-бір клип кесілмеді.")
        return 1

    print(f"[clipper] {len(made)} клип дайын:")
    for p in made:
        print("  " + p.name)

    if args.push:
        rel = [str(p.relative_to(repo)) for p in made]
        subprocess.run(["git", "-C", str(repo), "add", *rel], check=True)
        subprocess.run(
            ["git", "-C", str(repo), "commit", "-m",
             f"clip: cinematic auto-capture {date_tag}"],
            check=True,
        )
        subprocess.run(["git", "-C", str(repo), "push"], check=True)
        print("[clipper] git push OK — YouTube workflow клиптерді жүктейді.")

    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Кинематик clipper")
    sub = parser.add_subparsers(dest="mode", required=True)

    w = sub.add_parser("watch")
    w.add_argument("--out", required=True)
    w.add_argument("--duration", type=float, default=0.0)

    c = sub.add_parser("cut")
    c.add_argument("--recording", required=True)
    c.add_argument("--markers", required=True)
    c.add_argument("--session-start", type=float, required=True, help="epoch ms")
    c.add_argument("--repo", required=True)
    c.add_argument("--push", action="store_true")

    args = parser.parse_args()
    if args.mode == "watch":
        return cmd_watch(args)
    return cmd_cut(args)


if __name__ == "__main__":
    sys.exit(main())
