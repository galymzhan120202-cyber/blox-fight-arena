#!/usr/bin/env python3
"""Бір рет ЖЕРГІЛІКТІ компьютерде іске қосылады — YouTube OAuth логинін
браузерде ашып, youtube_token.json файлын шығарады (мазмұнын GitHub Secret-ке
YOUTUBE_TOKEN_JSON деп сақтайсыз).

Алдымен client_secrets.json файлын осы папкаға салыңыз:
  Google Cloud Console -> APIs & Services -> Credentials
  -> Create Credentials -> OAuth client ID -> Desktop app -> Download JSON

Маңызды: OAuth consent screen "Testing" емес, "In production" күйінде болуы
керек — олай болмаса, шыққан refresh token 7 күннен кейін өшіп, авто-жүктеу
үзіліп қалады.
"""

from pathlib import Path

from google_auth_oauthlib.flow import InstalledAppFlow

SCOPES = ["https://www.googleapis.com/auth/youtube.upload"]
CLIENT_SECRETS_FILE = Path(__file__).parent / "client_secrets.json"
TOKEN_FILE = Path(__file__).parent / "youtube_token.json"


def main() -> None:
    if not CLIENT_SECRETS_FILE.exists():
        raise SystemExit(
            f"'{CLIENT_SECRETS_FILE.name}' табылмады. Google Cloud Console-дан "
            "жүктеп алып, осы папкаға (automation/upload/) салыңыз."
        )

    flow = InstalledAppFlow.from_client_secrets_file(str(CLIENT_SECRETS_FILE), SCOPES)
    credentials = flow.run_local_server(port=0)

    TOKEN_FILE.write_text(credentials.to_json(), encoding="utf-8")
    print(f"[OK] {TOKEN_FILE.name} жасалды.")
    print("Мазмұнын GitHub repo -> Settings -> Secrets -> YOUTUBE_TOKEN_JSON деп сақтаңыз.")
    print("(Бұл файлды өзіңіз де .gitignore-ға қосып, репозиторийге commit етпеңіз.)")


if __name__ == "__main__":
    main()
