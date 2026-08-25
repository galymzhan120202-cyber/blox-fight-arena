# Blox Fight Arena — Архитектура

## Шолу

Blox Fight Arena — Roblox платформасында жұмыс істейтін PvP/PvE fighting-arena ойыны, класс жүйесі, боссы бар PvE режимі, progression/leaderboard, cosmetics, клан жүйесі және Robux монетизациясы бар. Бұған қоса, ойын ішіндегі қызықты сәттерді YouTube Shorts арқылы жарнамалайтын жартылай автоматтандырылған контент-воронка қосымша модуль ретінде тіркеледі.

## Технологиялық стек

| Қабат | Технология | Себебі |
|---|---|---|
| Ойын клиенті/сервері | Roblox Studio, Luau | Roblox платформасының жалғыз опциясы |
| Код синхрондау | Rojo | Luau кодын файл түрінде жазып, git-пен бақылауға мүмкіндік береді |
| Ойыншы деректері | DataStoreService (session-lock wrapper) | Деректердің қайталама жазылып, бұзылуынан қорғайды |
| Жаһандық рейтинг | OrderedDataStore | Сұрыпталған сұраныстарға арналған |
| Монетизация | MarketplaceService | Gamepass/Developer Product стандарты |
| YouTube жүктеу | GitHub Actions (cron) + YouTube Data API v3 | Толық автоматты, серверсіз |

## Негізгі принцип: Server-Authoritative Combat

Барлық combat/ability логикасы серверде тексеріледі. Клиент тек "мен мына абилитиді қолданғым келеді" деген сұрау (RemoteEvent) жібереді; сервер cooldown, resource, hit-ті тексеріп барып нәтижені барлық клиентке қайта таратады (VFX үшін). Бұл ережені бұзу — Roblox ойындарындағы ең кең тараған читерлік тесігі, сондықтан әр жаңа feature осы принципке сай жазылуы керек.

## Модульдік құрылым

```
default.project.json
src/
  ReplicatedStorage/
    Modules/
      Classes/     -- ClassDefinitions, Warrior (дайын) | Archer, Mage, Assassin (жоспарда)
      Data/        -- PlayerDataSchema, LevelCurve, RankTiers (дайын) | ItemDatabase, CosmeticsDatabase, ClanSchema (жоспарда)
    RemoteEvents/  -- UseAbility.model.json (дайын)
  ServerScriptService/
    Server/
      init.server.lua       -- bootstrap: барлық Init()-ті шақырады
      ClassService.lua       -- дайын
      PlayerDataService.lua  -- дайын
      CombatService.lua      -- дайын
      RankService.lua        -- дайын
      LeaderboardService.lua -- дайын
      DummyService.lua       -- дайын (жаттығу қуыршағы, тестілеу үшін)
      BossService.lua        -- жоспарда (Fase 3)
      DynamicEventService.lua -- жоспарда (Fase 3)
      ClanService.lua         -- жоспарда (Fase 4)
      MonetizationService.lua -- жоспарда (Fase 4)
      ArenaService.lua        -- жоспарда (Fase 3)
  StarterPlayer/StarterPlayerScripts/Client/
    init.client.lua  -- bootstrap
    CombatController.lua  -- дайын
    HealthBar.lua          -- дайын
  ServerStorage/
```

Толық көрнекі шолу (жүйе картасы, диаграмма, статус): [Blox Fight Arena жүйелері](https://claude.ai/code/artifact/1fee9933-bb18-4994-ba4a-a5be0cd24da9).

### Жүйелер арасындағы байланыс

- **Class & Combat**: `ClassService` кейіпкерге Warrior статын береді және `Damageable` тегін қояды → `CombatService` cooldown/range/facing тексеріп damage береді → нәтиже `PlayerDataService`-ке (XP) және кілл болса `RankService`-ке (RP, тек нақты ойыншыға қарсы) тарайды.
- **Progression**: `PlayerDataService.AddXP` шақырылған сайын `LevelCurve`-пен ағымдағы деңгей есептеледі (100×деңгей формуласы), деңгей өзгерсе Output-қа лог жазылады.
- **Rank/Leaderboard**: `RankService` kill/death бойынша RankPoints өзгертеді (`RankTiers`-пен Bronze→Heroic дәрежесіне түрлендіріледі) → `LeaderboardService` осы RankPoints-ты 60 секунд сайын және ойыншы шыққанда OrderedDataStore-ға жазады.
- **DataStore қолжетімсіздігі**: жоба publish етілмесе, `PlayerDataService`/`LeaderboardService` DataStore шақыруын `pcall`-мен қорғап, ескерту беріп, тек сессия ішінде (сақтаусыз) жұмыс істейді — ойын құламайды.
- **Boss/Dynamic Events/Clans/Monetization**: әлі кодталған жоқ, төмендегі фаза кестесінде.

## YouTube авто-маркетинг модулі

**Шектеу**: GitHub Actions Roblox клиентін іске қосып, экранды жаза алмайды (GPU rendering жоқ, headless емес), әрі бот-клиенттер Roblox ToS шеңберінде тәуекелді. Сондықтан үш бөлікке бөлінеді:

1. **Event logging (ойын жағы)** — `BossService`/`CombatService` highlight сәттерін (boss kill, killstreak, clutch win) HttpService арқылы сыртқы webhook-ке уақыт белгісімен жібереді.
2. **Видео жазу (сыртқы, қолмен/жартылай авто)** — нақты ойыншы сессиясынан OBS арқылы жазылады, логталған таймкодтар бойынша ffmpeg клипті кеседі.
3. **Авто-жүктеу (толық автоматты)** — GitHub Actions cron job дайын клиптерді YouTube Data API v3 арқылы Shorts ретінде жүктейді, сипаттамаға ойын сілтемесін қосады.

Толығырақ: [`automation/README.md`](automation/README.md).

## Фазалық жол картасы

1. **Fase 0** — Архитектура құжаты + Rojo қаңқа құрылымы. ✅ дайын
2. **Fase 1** — 1 класс (Warrior) + негізгі server-authoritative combat. ✅ дайын
3. **Fase 2** — PlayerDataService + XP/Level + Rank (RP, Bronze→Heroic) + Leaderboard backend. ✅ дайын
4. **Fase 3** — 4 класс, класс таңдау UI, Boss fight (дизайны бар — бас/көз/иық/қылыш, шабуыл жасайды), Dynamic Events, қару жүйесі + randomizer, қару визуалы + сермеу анимациясы + тию эффектісі, матч режимдері (FFA / Team 2ге2-2ге1 / Boss). ✅ дайын
5. **Fase 4** — Coins валютасы, 6 скин (Cosmetics), клан құру/қосылу/шығу, Gamepass/DevProduct фреймворкі (Monetization). ✅ дайын (Monetization нақты ID-лерсіз тексерілмейді, publish керек)
6. **Fase 5** — YouTube event-logging (`HighlightService`, дайын) + upload автоматтандыру (сыртқы, жоспарда). ⏳ ішінара дайын
7. **Fase 6** — 4 арена (Классикалық/Лава/Аспан аралдары/Мұзды құрсау), UI арқылы ауыстыру, ойыншы/Boss автотелепорт. ✅ дайын
8. **Fase 7** — `BotService`: жүре алатын, шаба алатын, өлетін/тірілетін AI боттар (0-3), Dummy-ден айырмашылығы — шынымен қарсыласады, killstreak/rank/feed жүйесіне толық қосылған. ✅ дайын
9. **Fase 8** — `RoundService` (раунд бастау/тоқтату, класс/қару құлыптау, MVP хабарламасы) + `LeaderboardUI` (рейтинг тақтасы, Studio-да publish-сыз да қосылған ойыншылардан тексеруге болады) + соққы кезінде кері серпу (knockback) + "сізді жеңді" хабарламасы. ✅ дайын
10. **Fase 9** — Dummy бөлек "Training" матч режиміне көшірілді (PvP өшеді, тек Dummy-ге қатысты). Boss HP енді ойыншы санына қарай өседі (350 + 150×ойыншы саны — 4 ойыншыға ~950 HP). Респавн уақыты нақтыланды (3с). Boss жеңгенде Coins сыйақысы бұрыннан бар (+75). ✅ дайын

## Аудитте табылған және түзетілген қателер

- `ClassDefinitions.Get("Get")` арқылы серверде қате тудыруға болатын эксплойт — түзетілді (lookup кестесі бөлек шығарылды).
- Boss-ты арена шетінен құлатып тегін жеңуге болатын эксплойт — KillFloor Boss-ты елемейтін болды + Boss ешқашан SAFE_RADIUS-тан аспайды.
- Ұзын қарулар (Staff, Spear) дене арқылы өтіп кететін көрініс — оффсет қайта қару ұзындығына сай есептеледі.
- `WeaponService`/`MatchModeService` жаңа қосылған ойыншыға ағымдағы режимді жібермейтін — түзетілді.
- Bow ешбір кемшіліксіз ең үстем қару болатын теңдессіздік — Damage/Range азайтылды.

## Белгілі шектеулер

- DataStore тек ойын **publish** етілгенде сақтайды — қазір тек сессия ішінде жұмыс істейді.
- Rank/RP жүйесі әлі 2 нақты ойыншымен тексерілген жоқ (dummy-ге RP есептелмейді, әдейі).
- Leaderboard-тың экрандық (in-game UI) көрінісі жоқ, тек backend дайын.

## Келесі қадам

Fase 3: Archer/Mage/Assassin кластарын Warrior үлгісімен қосу, немесе Boss fight жүйесін бастау.
