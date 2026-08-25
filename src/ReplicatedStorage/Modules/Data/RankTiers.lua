local TIERS = {
	{ Name = "Bronze", MinRP = 0 },
	{ Name = "Silver", MinRP = 500 },
	{ Name = "Gold", MinRP = 1000 },
	{ Name = "Platinum", MinRP = 1500 },
	{ Name = "Diamond", MinRP = 2000 },
	{ Name = "Heroic", MinRP = 2500 },
}

local RankTiers = {}

function RankTiers.GetTier(rankPoints: number): string
	local current = TIERS[1]
	for _, tier in TIERS do
		if rankPoints >= tier.MinRP then
			current = tier
		end
	end
	return current.Name
end

return RankTiers
