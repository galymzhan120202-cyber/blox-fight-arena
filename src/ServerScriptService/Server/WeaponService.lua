local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponDatabase = require(ReplicatedStorage.Modules.Data.WeaponDatabase)
local WeaponModelService = require(script.Parent.WeaponModelService)
local WeaponSkinService = require(script.Parent.WeaponSkinService)
local AdminService = require(script.Parent.AdminService)

local RANDOMIZER_INTERVAL = 40

local CLASS_DEFAULT_WEAPON = {
	Warrior = "Sword",
	Archer = "Bow",
	Mage = "Staff",
	Assassin = "Daggers",
}

local SelectClassEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SelectClass")
local SelectWeaponEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SelectWeapon")
local WeaponChangedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("WeaponChanged")
local SetGameModeEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SetGameMode")
local GameModeChangedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("GameModeChanged")

local WeaponService = {}

local playerWeapons = {}
local playerClassName = {}
local currentMode = "Random"
local locked = false

local function weaponNames()
	local names = {}
	for name in WeaponDatabase do
		table.insert(names, name)
	end
	return names
end

local function setWeapon(player: Player, weaponName: string)
	if not WeaponDatabase[weaponName] then
		return
	end

	playerWeapons[player] = weaponName
	WeaponChangedEvent:FireClient(player, weaponName)

	if player.Character then
		local skinId = WeaponSkinService.GetEquippedSkinId(player, weaponName)
		WeaponModelService.Equip(player, player.Character, weaponName, skinId)
	end
end

local function resetToClassDefault(player: Player)
	local className = playerClassName[player] or "Warrior"
	local defaultWeapon = CLASS_DEFAULT_WEAPON[className]
	if defaultWeapon then
		setWeapon(player, defaultWeapon)
	end
end

-- Классқа тәуелсіз, тегін қару таңдау (дүкен-стиль UI). Раунд құлыпталғанда
-- (RoundService active) немесе Bot/Boss/Random режимнің өз логикасымен қайшы келгенде
-- де жай ғана қабылданбайды — класс таңдаудағыдай locked flag-ты пайдаланады.
function WeaponService.SelectWeapon(player: Player, weaponName: string): boolean
	if locked or not WeaponDatabase[weaponName] then
		return false
	end

	setWeapon(player, weaponName)
	return true
end

function WeaponService.GetPlayerWeapon(player: Player)
	local weaponName = playerWeapons[player]
	return weaponName and WeaponDatabase[weaponName]
end

function WeaponService.GetMode(): string
	return currentMode
end

function WeaponService.SetLocked(value: boolean)
	locked = value
end

function WeaponService.SetMode(mode: string): boolean
	if mode ~= "Random" and mode ~= "Classic" then
		return false
	end

	currentMode = mode
	GameModeChangedEvent:FireAllClients(currentMode)
	print("[GameMode] Режим ауыстырылды: " .. mode)

	if mode == "Classic" then
		for _, player in Players:GetPlayers() do
			resetToClassDefault(player)
		end
	end

	return true
end

local function onPlayerAdded(player: Player)
	GameModeChangedEvent:FireClient(player, currentMode)

	player.CharacterAdded:Connect(function(character)
		if not playerWeapons[player] then
			playerClassName[player] = playerClassName[player] or "Warrior"
			resetToClassDefault(player)
		else
			WeaponChangedEvent:FireClient(player, playerWeapons[player])
			local skinId = WeaponSkinService.GetEquippedSkinId(player, playerWeapons[player])
			WeaponModelService.Equip(player, character, playerWeapons[player], skinId)
		end
	end)
end

function WeaponService.Init()
	Players.PlayerAdded:Connect(onPlayerAdded)

	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
		if player.Character then
			playerClassName[player] = playerClassName[player] or "Warrior"
			resetToClassDefault(player)
		end
	end

	Players.PlayerRemoving:Connect(function(player)
		playerWeapons[player] = nil
		playerClassName[player] = nil
	end)

	SelectClassEvent.OnServerEvent:Connect(function(player, className)
		if locked or typeof(className) ~= "string" or not CLASS_DEFAULT_WEAPON[className] then
			return
		end

		playerClassName[player] = className
		setWeapon(player, CLASS_DEFAULT_WEAPON[className])
	end)

	SelectWeaponEvent.OnServerEvent:Connect(function(player, weaponName)
		if typeof(weaponName) == "string" then
			WeaponService.SelectWeapon(player, weaponName)
		end
	end)

	SetGameModeEvent.OnServerEvent:Connect(function(player, mode)
		if not AdminService.IsAdmin(player) or typeof(mode) ~= "string" then
			return
		end
		WeaponService.SetMode(mode)
	end)

	local names = weaponNames()

	task.spawn(function()
		while true do
			task.wait(RANDOMIZER_INTERVAL)

			if currentMode ~= "Random" or locked then
				continue
			end

			for _, player in Players:GetPlayers() do
				if playerWeapons[player] then
					setWeapon(player, names[math.random(1, #names)])
					print(string.format("[Randomizer] %s қаруы: %s", player.Name, playerWeapons[player]))
				end
			end
		end
	end)
end

return WeaponService
