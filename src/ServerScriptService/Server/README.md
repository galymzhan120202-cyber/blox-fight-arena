# Server Services

Сервер-авторитативті қызметтер, әрқайсысы бір жауапкершілік аймағы:

- `PlayerDataService.lua` — DataStore жүктеу/сақтау, session-lock
- `CombatService.lua` — hit detection, damage есептеу (соңғы шешім осында)
- `ClassService.lua` — ability cooldown/resource валидациясы
- `BossService.lua` — PvE boss spawn, state machine, loot distribution
- `DynamicEventService.lua` — карта оқиғалары (meteor, fog, lava)
- `LeaderboardService.lua` — OrderedDataStore жаңарту
- `ClanService.lua` — клан құру/мүшелік/рейтинг
- `MonetizationService.lua` — Gamepass/DevProduct, жалғыз орталық ProcessReceipt
- `ArenaService.lua` — арена/матч lifecycle, boss/event триггерлеу

Fase 1: тек `CombatService.lua`, `ClassService.lua`, `ArenaService.lua` толтырылады.
