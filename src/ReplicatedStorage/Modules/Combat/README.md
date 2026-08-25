# Combat

Client пен server ортақ пайдаланатын таза логика: `DamageCalculator.lua`, `HitDetection.lua`, `StatusEffects.lua`.
Соңғы шешім (кімге қанша урон тиеді) әрқашан `ServerScriptService/Server/CombatService.lua`-да қабылданады — бұл модульдер тек есептеу құралдары, авторитет емес.
