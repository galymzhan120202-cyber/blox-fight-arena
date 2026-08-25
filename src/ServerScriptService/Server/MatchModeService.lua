local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BossService = require(script.Parent.BossService)
local DummyService = require(script.Parent.DummyService)

local SetMatchModeEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SetMatchMode")
local MatchModeChangedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("MatchModeChanged")

local VALID_MODES = { FFA = true, Team = true, Boss = true, Training = true }

local MatchModeService = {}

local currentMode = "FFA"
local teamA: Team
local teamB: Team

local function ensureTeams()
	if teamA and teamB then
		return
	end

	teamA = Instance.new("Team")
	teamA.Name = "Team A"
	teamA.TeamColor = BrickColor.new("Really blue")
	teamA.AutoAssignable = false
	teamA.Parent = Teams

	teamB = Instance.new("Team")
	teamB.Name = "Team B"
	teamB.TeamColor = BrickColor.new("Really red")
	teamB.AutoAssignable = false
	teamB.Parent = Teams
end

local function assignToSmallerTeam(player: Player)
	ensureTeams()

	local countA, countB = 0, 0
	for _, otherPlayer in Players:GetPlayers() do
		if otherPlayer.Team == teamA then
			countA += 1
		elseif otherPlayer.Team == teamB then
			countB += 1
		end
	end

	player.Team = (countA <= countB) and teamA or teamB
end

function MatchModeService.GetMode(): string
	return currentMode
end

function MatchModeService.IsSameTeam(playerA: Player, playerB: Player): boolean
	return playerA.Team ~= nil and playerA.Team == playerB.Team
end

function MatchModeService.SetMode(mode: string): boolean
	if not VALID_MODES[mode] then
		return false
	end

	currentMode = mode
	MatchModeChangedEvent:FireAllClients(currentMode)
	print("[MatchMode] Режим ауыстырылды: " .. mode)

	BossService.SetActive(mode == "Boss")
	DummyService.SetActive(mode == "Training")

	if mode == "Team" then
		ensureTeams()
		for _, player in Players:GetPlayers() do
			assignToSmallerTeam(player)
		end
	else
		for _, player in Players:GetPlayers() do
			player.Team = nil :: any
		end
	end

	return true
end

function MatchModeService.Init()
	Players.PlayerAdded:Connect(function(player)
		MatchModeChangedEvent:FireClient(player, currentMode)

		if currentMode == "Team" then
			assignToSmallerTeam(player)
		end
	end)

	SetMatchModeEvent.OnServerEvent:Connect(function(_player, mode)
		if typeof(mode) ~= "string" then
			return
		end
		MatchModeService.SetMode(mode)
	end)
end

return MatchModeService
