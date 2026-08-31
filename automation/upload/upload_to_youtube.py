#!/usr/bin/env python3
"""Дайын клиптерді YouTube Shorts ретінде автоматты жүктейді.

Алдымен `get_youtube_token.py`-ды ЖЕРГІЛІКТІ бір рет іске қосып,
`youtube_token.json` жасаңыз (нұсқаулық сол файлдың ішінде).

Қажет орта айнымалылары (GitHub Secrets/Variables):
  YOUTUBE_TOKEN_JSON   (get_youtube_token.py шығарған youtube_token.json мазмұны)
  GAME_LINK            (Roblox ойын сілтемесі, сипаттамаға қосылады)
  YOUTUBE_PRIVACY      (public/unlisted/private — бос болса "public", міндетті емес)
  TELEGRAM_BOT_TOKEN   (Telegram бот токені — жүктеу нәтижесі туралы хабарлау үшін, міндетті емес)
  TELEGRAM_CHAT_ID     (хабарлама жіберілетін chat/user ID, міндетті емес)

Клиптер:            automation/upload/clips/*.mp4  (OBS/ffmpeg-пен сырттан дайындалады)
Жүктелгендер тізімі: automation/upload/uploaded.json (қайта жүктемеу үшін)
"""

import json
import os
import urllib.error
import urllib.request
from pathlib import Path

import google.auth.transport.requests
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

CLIPS_DIR = Path(__file__).parent / "clips"
UPLOADED_LOG = Path(__file__).parent / "uploaded.json"
TOKEN_FILE = Path(__file__).parent / "youtube_token.json"
GAME_LINK = os.environ.get("GAME_LINK", "")
VALID_PRIVACY = {"public", "unlisted", "private"}
PRIVACY_STATUS = (os.environ.get("YOUTUBE_PRIVACY") or "public").strip().lower()
if PRIVACY_STATUS not in VALID_PRIVACY:
    PRIVACY_STATUS = "public"
TELEGRAM_BOT_TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN", "")
TELEGRAM_CHAT_ID = os.environ.get("TELEGRAM_CHAT_ID", "")


def notify_telegram(text: str) -> None:
    if not TELEGRAM_BOT_TOKEN or not TELEGRAM_CHAT_ID:
        return

    url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
    payload = json.dumps({"chat_id": TELEGRAM_CHAT_ID, "text": text}).encode("utf-8")
    request = urllib.request.Request(
        url, data=payload, headers={"Content-Type": "application/json"}
    )
    try:
        urllib.request.urlopen(request, timeout=10)
    except urllib.error.URLError as error:
        print(f"[Telegram] Хабарлама жіберілмеді: {error}")


def load_uploaded() -> set:
    if UPLOADED_LOG.exists():
        return set(json.loads(UPLOADED_LOG.read_text(encoding="utf-8")))
    return set()


def save_uploaded(uploaded: set) -> None:
    UPLOADED_LOG.write_text(
        json.dumps(sorted(uploaded), ensure_ascii=False, indent=2), encoding="utf-8"
    )


def get_youtube_client():
    token_json = os.environ.get("YOUTUBE_TOKEN_JSON")
    if token_json:
        info = json.loads(token_json)
    elif TOKEN_FILE.exists():
        info = json.loads(TOKEN_FILE.read_text(encoding="utf-8"))
    else:
        raise SystemExit(
            "YOUTUBE_TOKEN_JSON орта айнымалысы да, youtube_token.json файлы да "
            "табылмады. Алдымен get_youtube_token.py-ды жергілікті іске қосыңыз."
        )

    credentials = Credentials.from_authorized_user_info(info)
    credentials.refresh(google.auth.transport.requests.Request())
    return build("youtube", "v3", credentials=credentials)


def upload_clip(youtube, clip_path: Path) -> None:
    title = clip_path.stem.replace("_", " ")[:90]
    description = f"Blox Fight Arena — қызықты сәт!\n\nОйынға кіру: {GAME_LINK}\n#Shorts #Roblox"

    body = {
        "snippet": {
            "title": title,
            "description": description,
            "categoryId": "20",  # Gaming
        },
        "status": {
            "privacyStatus": PRIVACY_STATUS,
            "selfDeclaredMadeForKids": False,
        },
    }

    media = MediaFileUpload(str(clip_path), chunksize=-1, resumable=True)
    request = youtube.videos().insert(part="snippet,status", body=body, media_body=media)

    response = None
    while response is None:
        _, response = request.next_chunk()

    video_url = f"https://youtu.be/{response['id']}"
    print(f"[Upload] {clip_path.name} -> {video_url} ({PRIVACY_STATUS})")
    notify_telegram(
        f"✅ Жаңа Shorts жүктелді! ({PRIVACY_STATUS})\n{title}\n{video_url}"
    )


def main() -> None:
    uploaded = load_uploaded()
    clips = sorted(CLIPS_DIR.glob("*.mp4")) if CLIPS_DIR.exists() else []
    pending = [clip for clip in clips if clip.name not in uploaded]

    if not pending:
        print("[Upload] Жаңа клип жоқ.")
        return

    youtube = get_youtube_client()

    for clip_path in pending:
        try:
            upload_clip(youtube, clip_path)
            uploaded.add(clip_path.name)
            save_uploaded(uploaded)
        except Exception as error:  # noqa: BLE001 - CI логында толық қате көрінуі керек
            print(f"[Upload] Қате ({clip_path.name}): {error}")
            notify_telegram(f"❌ Жүктеу қатесі: {clip_path.name}\n{error}")


if __name__ == "__main__":
    main()
