-- DPS = Damage / Cooldown. Ұзын Range + жоғары Speed бар класс (Archer, Mage) ең жоғары
-- DPS-ті де иеленбеуі керек — қашықтық/жылдамдық артықшылығының өзі баланс. SingleTarget=true
-- қарулар (снаряд/сиқыр) бір соққыда тек ЕҢ ЖАҚЫН нысанаға тиеді (CombatService.lua);
-- SingleTarget жоқ қарулар (жақынтабан) доғадағы барлық нысанаға тиеді (cleave).
return {
	Sword = { Name = "Sword", Damage = 20, Cooldown = 1.5, Range = 8 }, -- 13.3 DPS, tank/bruiser (cleave)
	Bow = { Name = "Bow", Damage = 9, Cooldown = 0.8, Range = 14, SingleTarget = true }, -- 11.3 DPS, poke/kite
	Staff = { Name = "Staff", Damage = 26, Cooldown = 2.2, Range = 16, SingleTarget = true }, -- 11.8 DPS, big single burst
	Daggers = { Name = "Daggers", Damage = 35, Cooldown = 1.8, Range = 5 }, -- 19.4 DPS, glass-cannon melee
	Hammer = { Name = "Hammer", Damage = 42, Cooldown = 3.0, Range = 7 }, -- 14.0 DPS, slow bruiser (cleave)
	Spear = { Name = "Spear", Damage = 18, Cooldown = 1.2, Range = 12 }, -- 15.0 DPS, all-rounder poke (cleave)
}
