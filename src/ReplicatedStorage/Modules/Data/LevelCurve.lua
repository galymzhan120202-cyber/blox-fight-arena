local LevelCurve = {}

function LevelCurve.XPForLevel(level: number): number
	return 100 * level
end

function LevelCurve.LevelFromXP(totalXP: number): (number, number, number)
	local level = 1
	local remainingXP = totalXP

	while remainingXP >= LevelCurve.XPForLevel(level) do
		remainingXP -= LevelCurve.XPForLevel(level)
		level += 1
	end

	return level, remainingXP, LevelCurve.XPForLevel(level)
end

return LevelCurve
