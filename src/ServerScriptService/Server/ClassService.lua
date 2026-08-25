local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClassDefinitions = require(ReplicatedStorage.Modules.Classes.ClassDefinitions)

local DAMAGEABLE_TAG = "Damageable"
local DEFAULT_CLASS = "Warrior"

local SelectClassEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SelectClass")

local ClassService = {}

local selectedClassName = {}
local playerClasses = {}
local locked = false

local function applyClass(player: Player, character: Model, className: string)
	local classDef = ClassDefinitions.Get(className)
	if not classDef then
		return
	end

	playerClasses[player] = classDef

	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.MaxHealth = classDef.MaxHealth
	humanoid.Health = classDef.MaxHealth
	humanoid.WalkSpeed = classDef.WalkSpeed

	CollectionService:AddTag(character, DAMAGEABLE_TAG)
end

local function onCharacterAdded(player: Player, character: Model)
	local className = selectedClassName[player] or DEFAULT_CLASS
	applyClass(player, character, className)
end

local function onPlayerAdded(player: Player)
	selectedClassName[player] = DEFAULT_CLASS
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
end

function ClassService.GetPlayerClass(player: Player)
	return playerClasses[player]
end

function ClassService.SetLocked(value: boolean)
	locked = value
end

function ClassService.SetPlayerClass(player: Player, className: string): boolean
	if locked or not ClassDefinitions.Get(className) then
		return false
	end

	selectedClassName[player] = className

	if player.Character then
		applyClass(player, player.Character, className)
	end

	return true
end

function ClassService.Init()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player)
		playerClasses[player] = nil
		selectedClassName[player] = nil
	end)

	SelectClassEvent.OnServerEvent:Connect(function(player, className)
		if typeof(className) ~= "string" then
			return
		end
		ClassService.SetPlayerClass(player, className)
	end)

	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
		if player.Character then
			onCharacterAdded(player, player.Character)
		end
	end
end

return ClassService
