-- DPS = Damage / Cooldown. Ұзын Range + жоғары Speed бар класс (Archer, Mage) ең жоғары
-- DPS-ті де иеленбеуі керек — қашықтық/жылдамдық артықшылығының өзі баланс. SingleTarget=true
-- қарулар (снаряд/сиқыр) бір соққыда тек ЕҢ ЖАҚЫН нысанаға тиеді (CombatService.lua);
-- SingleTarget жоқ қарулар (жақынтабан) доғадағы барлық нысанаға тиеді (cleave).
return {
	Sword = { Name = "Sword", Damage = 14, Cooldown = 1.05, Range = 8 }, -- 13.3 DPS, tank/bruiser (cleave)
	Bow = { Name = "Bow", Damage = 6, Cooldown = 0.55, Range = 14, SingleTarget = true }, -- 10.9 DPS, poke/kite
	Staff = { Name = "Staff", Damage = 19, Cooldown = 1.6, Range = 16, SingleTarget = true }, -- 11.9 DPS, big single burst
	Daggers = { Name = "Daggers", Damage = 25, Cooldown = 1.3, Range = 5 }, -- 19.2 DPS, glass-cannon melee
	Hammer = { Name = "Hammer", Damage = 30, Cooldown = 2.15, Range = 7 }, -- 14.0 DPS, slow bruiser (cleave)
	Spear = { Name = "Spear", Damage = 13, Cooldown = 0.85, Range = 12 }, -- 15.3 DPS, all-rounder poke (cleave)
}
