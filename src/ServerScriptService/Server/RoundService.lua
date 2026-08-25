local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClassService = require(script.Parent.ClassService)
local WeaponService = require(script.Parent.WeaponService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local NotificationService = require(script.Parent.NotificationService)
local AdminService = require(script.Parent.AdminService)

local SetRoundActiveEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SetRoundActive")
local RoundChangedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("RoundChanged")

local RoundService = {}

local roundActive = false
local roundStartKills = {}
local getBotCount: (() -> number)?

function RoundService.SetBotCountProvider(fn: () -> number)
	getBotCount = fn
end

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
	SetRoundActiveEvent.OnServerEvent:Connect(function(player, active)
		if not (AdminService.IsAdmin(player) and typeof(active) == "boolean") then
			return
		end

		if active then
			local botCount = getBotCount and getBotCount() or 0
			if botCount <= 0 and #Players:GetPlayers() < 2 then
				NotificationService.Toast(
					player,
					"Алдымен боттар қосыңыз немесе басқа ойыншы кірсін!",
					Color3.fromRGB(220, 80, 80)
				)
				return
			end
		end

		RoundService.SetActive(active)
	end)

	Players.PlayerAdded:Connect(function(player)
		RoundChangedEvent:FireClient(player, roundActive)
	end)
end

return RoundService
