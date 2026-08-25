local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClassService = require(script.Parent.ClassService)
local WeaponService = require(script.Parent.WeaponService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local NotificationService = require(script.Parent.NotificationService)

local SetRoundActiveEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SetRoundActive")
local RoundChangedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("RoundChanged")

local RoundService = {}

local roundActive = false
local roundStartKills = {}

local function announceMvp()
	local mvpPlayer, mvpKills = nil, 0

	for _, player in Players:GetPlayers() do
		local data = PlayerDataService.Get(player)
		if data then
			local killsThisRound = data.Kills - (roundStartKills[player] or data.Kills)
			if killsThisRound > mvpKills then
				mvpPlayer, mvpKills = player, killsThisRound
			end
		end
	end

	if mvpPlayer then
		NotificationService.ToastAll(
			string.format("РАУНД MVP — %s (%d kill)!", mvpPlayer.Name, mvpKills),
			Color3.fromRGB(255, 215, 0)
		)
	end
end

function RoundService.IsActive(): boolean
	return roundActive
end

function RoundService.SetActive(active: boolean)
	if roundActive == active then
		return
	end

	roundActive = active
	ClassService.SetLocked(active)
	WeaponService.SetLocked(active)
	RoundChangedEvent:FireAllClients(active)

	if active then
		roundStartKills = {}
		for _, player in Players:GetPlayers() do
			local data = PlayerDataService.Get(player)
			roundStartKills[player] = data and data.Kills or 0
		end

		NotificationService.ToastAll("РАУНД БАСТАЛДЫ! Класс/қару енді ауыспайды.", Color3.fromRGB(120, 220, 140))
	else
		announceMvp()
		NotificationService.ToastAll("Раунд аяқталды — қайта дайындалыңыз.", Color3.fromRGB(200, 200, 210))
	end

	print(string.format("[Round] %s", active and "Басталды" or "Аяқталды"))
end

function RoundService.Init()
	SetRoundActiveEvent.OnServerEvent:Connect(function(_player, active)
		if typeof(active) == "boolean" then
			RoundService.SetActive(active)
		end
	end)

	Players.PlayerAdded:Connect(function(player)
		RoundChangedEvent:FireClient(player, roundActive)
	end)
end

return RoundService
