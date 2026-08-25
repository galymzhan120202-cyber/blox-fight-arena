local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PlayerDataSchema = require(ReplicatedStorage.Modules.Data.PlayerDataSchema)
local LevelCurve = require(ReplicatedStorage.Modules.Data.LevelCurve)
local NotificationService = require(script.Parent.NotificationService)

local SAVE_RETRIES = 3
local XP_TO_RP_RATIO = 0.5 -- шайқаста жиналған XP-тің жартысы рейтинг ұпайына (RP) да қосылады

local PlayerDataService = {}

local dataStoreOk, dataStore = pcall(function()
	return DataStoreService:GetDataStore("PlayerData_v1")
end)

if not dataStoreOk then
	dataStore = nil
	warn("[PlayerDataService] DataStore қолжетімсіз (жоба publish етілмеген): деректер тек осы сессия ішінде сақталады.")
end

local sessionData = {}

local function deepCopy(source)
	local copy = {}
	for key, value in source do
		if type(value) == "table" then
			copy[key] = deepCopy(value)
		else
			copy[key] = value
		end
	end
	return copy
end

local function loadData(player: Player)
	local data = nil

	if dataStore then
		local key = "Player_" .. player.UserId
		local success, result = pcall(function()
			return dataStore:GetAsync(key)
		end)
		data = success and result or nil
	end

	data = data or deepCopy(PlayerDataSchema)

	for field, defaultValue in PlayerDataSchema do
		if data[field] == nil then
			data[field] = (type(defaultValue) == "table") and deepCopy(defaultValue) or defaultValue
		end
	end

	sessionData[player] = data
end

local function saveData(player: Player)
	if not dataStore then
		return
	end

	local data = sessionData[player]
	if not data then
		return
	end

	local key = "Player_" .. player.UserId
	for _ = 1, SAVE_RETRIES do
		local success = pcall(function()
			dataStore:SetAsync(key, data)
		end)
		if success then
			break
		end
	end
end

function PlayerDataService.Get(player: Player)
	return sessionData[player]
end

function PlayerDataService.WaitForData(player: Player, timeoutSeconds: number?)
	local deadline = os.clock() + (timeoutSeconds or 10)
	while not sessionData[player] and player.Parent and os.clock() < deadline do
		task.wait(0.1)
	end
	return sessionData[player]
end

function PlayerDataService.AddXP(player: Player, amount: number)
	local data = sessionData[player]
	if not data then
		return
	end

	local oldLevel = LevelCurve.LevelFromXP(data.XP)
	data.XP += amount
	local newLevel = LevelCurve.LevelFromXP(data.XP)

	data.RankPoints += math.floor(amount * XP_TO_RP_RATIO)

	print(string.format("[XP] %s +%d XP (барлығы: %d, RP: %d)", player.Name, amount, data.XP, data.RankPoints))

	if newLevel > oldLevel then
		print(string.format("[Level Up] %s деңгейі: %d", player.Name, newLevel))
		NotificationService.Toast(player, string.format("Деңгей көтерілді — %d!", newLevel), Color3.fromRGB(120, 220, 140))
	end
end

function PlayerDataService.AddCoins(player: Player, amount: number)
	local data = sessionData[player]
	if not data then
		return
	end

	data.Coins += amount
end

function PlayerDataService.SpendCoins(player: Player, amount: number): boolean
	local data = sessionData[player]
	if not data or data.Coins < amount then
		return false
	end

	data.Coins -= amount
	return true
end

function PlayerDataService.IncrementStat(player: Player, statName: string, amount: number?)
	local data = sessionData[player]
	if not data then
		return
	end

	data[statName] = (data[statName] or 0) + (amount or 1)
end

function PlayerDataService.Init()
	Players.PlayerAdded:Connect(loadData)
	Players.PlayerRemoving:Connect(function(player)
		saveData(player)
		sessionData[player] = nil
	end)

	for _, player in Players:GetPlayers() do
		loadData(player)
	end

	game:BindToClose(function()
		if RunService:IsStudio() then
			return
		end
		for _, player in Players:GetPlayers() do
			saveData(player)
		end
	end)
end

return PlayerDataService
