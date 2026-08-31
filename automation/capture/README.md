# Кинематик авто-түсіру (Фаза 2)

Ешкім ойнамай, бот-vs-бот төбелесін кинематик камерамен жазып, highlight
сәттерінен вертикаль Shorts клиптерін кесіп, `automation/upload/clips/`-ке
`git push` жасайды. Одан әрі қазіргі [YouTube workflow](../README.md) жүктейді.

```
run_session.ps1
  ├─ clipper.py watch      ← Roblox клиент логынан __BFA_HIGHLIGHT__ маркерлерін жинайды
  ├─ obs_ctl.py start      ← OBS жазуы (obs-websocket)
  ├─ roblox://…launchData=cinematic
  │     server: CinematicService  → тек боттан тұратын шексіз матч
  │     client: CinematicCamera   → режиссёр камерасы
  │             CinematicMarkers  → highlight → логқа маркер
  ├─ (N минут)
  ├─ obs_ctl.py stop       ← жазба файлының жолы
  └─ clipper.py cut --push ← ffmpeg клиптер → clips/ → git push
```

## Неге лог арқылы, webhook емес?

Ойын Roblox-тың бұлт серверлерінде жүреді — `HttpService` жазушы машинаға
`localhost` арқылы жете алмайды. Сондықтан `HighlightService` → `Highlight`
RemoteEvent → клиент `print("__BFA_HIGHLIGHT__ …")` → `clipper.py` сол клиенттің
`%LOCALAPPDATA%\Roblox\logs\*.log` файлынан оқиды. Тегін, туннельсіз.

## Бір реттік орнату (жазушы машина — ноутбук не GPU VM)

1. **ffmpeg** — PATH-та болсын (`ffmpeg -version`).
2. **Python пакеттері:** `pip install -r automation/capture/requirements.txt`
3. **OBS Studio 28+:**
   - `Tools → WebSocket Server Settings` → *Enable* → пароль қой.
   - `Settings → Video → Base & Output Resolution = 1080x1920` (вертикаль canvas).
   - Дереккөз қос: **Game Capture** (немесе Display Capture), кадрды толтыр.
   - `Settings → Output → Recording`: формат **mp4** (немесе mkv), жол — тұрақты папка.
   - OBS-ты **ашық** қалдыр (жазба websocket арқылы басталады).
4. **Roblox Player** орнатылған әрі **жазушы аккаунтпен кіріп қойылған** болсын
   (бір рет қолмен кір). Бөлек альт-аккаунт ұсынылады.
5. **Орта айнымалылары** (сессия скриптін шақырар алдында):

   | Айнымалы | Мәні |
   |---|---|
   | `OBS_WS_PASSWORD` | OBS websocket паролі |
   | `OBS_WS_PORT` | әдепкі `4455` |

6. **Тест:** OBS ашық тұрғанда —
   ```powershell
   powershell -File automation/capture/run_session.ps1 -DurationSeconds 300
   ```

## Studio-да тексеру (машинасыз)

Rojo sync қосулы кезде Studio-да Play → Command Bar-да:
```lua
workspace:SetAttribute("CinematicMode", true)
```
→ боттар толып, матч өзі жүреді, камера режиссёр режиміне ауысады, Output-та
`[Highlight] …` шығады. `false` қойсаң — тоқтайды.

## Автоматтандыру — ноутбук ұйқыдан оянады (картасыз, тегін)

Task Scheduler → жаңа тапсырма:
- **Trigger:** күн сайын, мыс. 03:00
- **Action:** `powershell.exe -File "D:\Blox Fight Arena\automation\capture\run_session.ps1" -DurationSeconds 420`
- **Conditions:** ✔ *Wake the computer to run this task*, ✔ *Start only if on AC power*
- **Settings:** ✔ *Run whether user is logged on or not* (немесе logon болсын)

Windows Power Options: *Sleep → Allow wake timers = Enabled*, әрі
*қақпақты жапқанда (AC): ешнәрсе істемеу*. Ноут ұйқыда → өзі оянады → жазады →
`run_session.ps1` соңында қаласаң `rundll32 powrprof.dll,SetSuspendState 0,1,0`
қосып қайта ұйқыға жіберуге болады.

> Толық power-off болмауы керек (ұйқы/hibernate болсын), әйтпесе Wake-on-LAN
> роутерден бөлек бапталады.

## Фаза 3 — GCP GPU VM (қаласаң, ноут мүлдем өшік тұрсын)

Картасыз мүмкін емес (барлық бұлт GPU үшін карта сұрайды). Несиемен ~1–2 жыл тегін.
Қысқаша: GitHub Actions cron → `gcloud compute instances start` → VM-нің
startup-script-і осы `run_session.ps1`-ды шақырады → `gcloud … stop`.
VM образын (Roblox + OBS + NVIDIA GRID драйвер) бір рет RDP-мен жасайсың.
Толық нұсқаулық Фаза 3-те қосылады.
