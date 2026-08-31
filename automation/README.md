# YouTube авто-маркетинг модулі

Ойын кодынан бөлек — Roblox жобасының Rojo синхрондауына қатыспайды.

## Шектеу

GitHub Actions Roblox клиентін іске қосып, экранды жаза алмайды (GPU rendering жоқ, headless орта). Сондықтан толық "human-in-the-loop-сыз" автоматика мүмкін емес — үш бөлікке бөлінген:

## A. Event logging (ойын жағы) — ✅ дайын

`HighlightService.lua` (`../src/ServerScriptService/Server/HighlightService.lua`) — highlight сәттерін (Алғашқы қан, Кек, Killstreak, Boss жеңу) уақыт белгісімен Output-қа жазады және `HttpService:PostAsync` арқылы webhook-ке жібереді (`CombatService`/`BossService` шақырады).

**Іске қосу үшін:** `HighlightService.lua` ішіндегі `WEBHOOK_URL` айнымалысына нақты Discord/webhook сілтемесін қойыңыз (бос болса, тек Output-қа жазылады, сыртқа жіберілмейді). Роблокс жағында **Game Settings → Security → Enable HTTP Requests** қосулы болуы керек.

## B. Видео жазу (сыртқы, авто емес)

Нақты ойыншы сессиясынан OBS арқылы жазылады (Roblox ToS-ты бұзбау үшін бот-клиент емес, шынайы сессия ұсынылады). Логталған таймкодтар бойынша `ffmpeg` клипті кеседі. Бұл процесс әрдайым қосулы машинада (пайдаланушының компьютері/cloud VM) жүреді — GitHub Actions мұны орындай алмайды.

## C. Авто-жүктеу (толық автоматты) — ✅ дайын

- `upload/upload_to_youtube.py` — `clips/` папкасындағы жаңа `.mp4` файлдарды YouTube Data API v3 арқылы Shorts ретінде жүктейді, сипаттамаға `GAME_LINK` қосады, жүктелгендерді `uploaded.json`-ға жазып қайталап жүктемейді.
- `upload/get_youtube_token.py` — бір рет **жергілікті** іске қосылатын OAuth login скрипті.
- `../.github/workflows/youtube-upload.yml` — күн сайын (немесе қолмен) іске қосылатын GitHub Actions workflow.

### Баптау реті (дәлелденген схема, басқа жобадан)

1. **YouTube арнасын ашыңыз.**
2. **Google Cloud Console** → жоба (бар жобаны да пайдалануға болады) → **APIs & Services → Library** → `YouTube Data API v3` → Enable.
3. **APIs & Services → OAuth consent screen** баптаңыз (External). **Маңызды:** баптаудан кейін статусты **"Testing"-тен "In production"-ға ауыстырыңыз** — олай етпесеңіз, шыққан refresh token **7 күннен кейін өшіп қалады** да, авто-жүктеу үзіледі.
4. **APIs & Services → Credentials → Create Credentials → OAuth client ID → Desktop app** → JSON жүктеп алып, `automation/upload/client_secrets.json` деп сақтаңыз (бұл файл `.gitignore`-де, commit етілмейді).
5. Жергілікті: `pip install -r automation/upload/requirements.txt`, содан `python automation/upload/get_youtube_token.py` — браузерде сол YouTube арнаңызға тиесілі аккаунтпен логин болыңыз. Нәтижесінде `youtube_token.json` жасалады.
6. Repo → **Settings → Secrets and variables → Actions**:

| Атауы | Түрі | Мәні |
|---|---|---|
| `YOUTUBE_TOKEN_JSON` | Secret | `youtube_token.json` файлының толық мазмұны |
| `GAME_LINK` | Variable | Roblox ойынының сілтемесі |
| `YOUTUBE_PRIVACY` | Variable | `public` / `unlisted` / `private` — бос болса `public` (міндетті емес) |
| `TELEGRAM_BOT_TOKEN` | Secret | Telegram бот токені (міндетті емес — хабарландыру үшін) |
| `TELEGRAM_CHAT_ID` | Secret | Хабарлама жіберілетін chat/user ID (міндетті емес) |

Клиптерді `automation/upload/clips/` папкасына қойып, commit/push жасасаңыз (немесе workflow-ды қолмен іске қоссаңыз), келесі cron циклінде автоматты жүктеледі.

### Telegram хабарландыру (міндетті емес)

Әр сәтті/сәтсіз жүктеу туралы Telegram-ға хабар келеді (`upload/upload_to_youtube.py` ішіндегі `notify_telegram`). Баптау:

1. [@BotFather](https://t.me/BotFather)-дан бот жасап, токен алыңыз.
2. Жаңа ботпен жеке чат ашып, кез келген хабарлама жіберіңіз (bot сізге бірінші жаза алмайды — сіз бастауыңыз керек).
3. `https://api.telegram.org/bot<TOKEN>/getUpdates` арқылы `chat.id` мәнін табыңыз.
4. `TELEGRAM_BOT_TOKEN` мен `TELEGRAM_CHAT_ID`-ды GitHub Secrets-ке қосыңыз (жоғарыдағы кестені қараңыз).

Екеуі де бос болса, хабарландыру жай өткізіп жіберіледі (жүктеу процесіне әсер етпейді).

## Монетизация жоспары

`MonetizationService.lua` дайын (кодта), тек нақты ID-лерді Roblox Creator Dashboard-тан алып қою керек:

| Атауы | Түрі | Ұсынылған баға |
|---|---|---|
| VIP | Gamepass | ~99 Robux — XP/Coins +20%, VIP жапсырма |
| AllSkins | Gamepass | ~149 Robux — барлық скинді бірден ашады |
| 500 Coins | Developer Product | ~49 Robux |
| 1500 Coins | Developer Product | ~99 Robux |
| 5000 Coins | Developer Product | ~299 Robux |
