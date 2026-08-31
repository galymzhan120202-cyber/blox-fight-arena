#!/usr/bin/env python3
"""OBS жазуын obs-websocket (v5) арқылы басқару.

  python obs_ctl.py start     # жазуды бастайды
  python obs_ctl.py stop      # жазуды тоқтатып, файл жолын stdout-қа шығарады
  python obs_ctl.py status

Орта айнымалылары:
  OBS_WS_HOST      (әдепкі 127.0.0.1)
  OBS_WS_PORT      (әдепкі 4455)
  OBS_WS_PASSWORD  (OBS → Tools → WebSocket Server Settings-те қойылған пароль)

OBS 28+ құрамында obs-websocket бар. `pip install obsws-python`.
"""

import os
import sys
import time

try:
    import obsws_python as obs
except ImportError:
    print("obsws-python орнатылмаған: pip install obsws-python", file=sys.stderr)
    sys.exit(2)


def client() -> "obs.ReqClient":
    return obs.ReqClient(
        host=os.environ.get("OBS_WS_HOST", "127.0.0.1"),
        port=int(os.environ.get("OBS_WS_PORT", "4455")),
        password=os.environ.get("OBS_WS_PASSWORD", ""),
        timeout=10,
    )


def main() -> int:
    if len(sys.argv) < 2 or sys.argv[1] not in {"start", "stop", "status"}:
        print(__doc__)
        return 2

    action = sys.argv[1]
    cl = client()

    if action == "start":
        st = cl.get_record_status()
        if not st.output_active:
            cl.start_record()
            time.sleep(0.5)
        print("recording")
        return 0

    if action == "status":
        st = cl.get_record_status()
        print("active" if st.output_active else "idle")
        return 0

    # stop
    st = cl.get_record_status()
    if not st.output_active:
        print("", end="")
        return 0
    resp = cl.stop_record()
    # v5: stop_record() жауабында output_path болады
    path = getattr(resp, "output_path", "") or ""
    print(path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
