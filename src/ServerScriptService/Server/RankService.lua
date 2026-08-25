local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent.PlayerDataService)
local RankTiers = require(ReplicatedStorage.Modules.Data.RankTiers)

local KILL_RP = 20
local DEATH_RP = 10
local MIN_RP = 0

local RankService = {}

function RankService.AwardKill(player: Player)
	local data = PlayerDataService.Get(player)
	if not data then
		return
	end

	data.RankPoints += KILL_RP
	print(
		string.format(
			"[Rank] %s +%d RP (барлығы: %d, дәреже: %s)",
			player.Name,
			KILL_RP,
			data.RankPoints,
			RankTiers.GetTier(data.RankPoints)
		)
	)
end

function RankService.PenalizeDeath(player: Player)
	local data = PlayerDataService.Get(player)
	if not data then
		return
	end

	data.RankPoints = math.max(MIN_RP, data.RankPoints - DEATH_RP)
	print(
		string.format(
			"[Rank] %s -%d RP (барлығы: %d, дәреже: %s)",
			player.Name,
			DEATH_RP,
			data.RankPoints,
			RankTiers.GetTier(data.RankPoints)
		)
	)
end

return RankService
