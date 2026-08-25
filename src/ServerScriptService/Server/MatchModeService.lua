local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BossService = require(script.Parent.BossService)
local DummyService = require(script.Parent.DummyService)
local AdminService = require(script.Parent.AdminService)
local SquadService = require(script.Parent.SquadService)

local SetMatchModeEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SetMatchMode")
local MatchModeChangedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("MatchModeChanged")

local VALID_MODES = { Solo = true, Duo = true, Squad = true, Auto = true, Boss = true, Training = true }
local TEAM_SIZE = { Duo = 2, Squad = 4 } -- Auto = nil (шексіз, squad өлшемінің өзі шек болады)

local TEAM_COLORS = {
	"Really blue",
	"Really red",
	"Lime green",
	"New Yeller",
	"Really black",
	"Hot pink",
	"Cyan",
	"Deep orange",
}

local MatchModeService = {}

local currentMode = "Solo"
local activeTeams: { Team } = {}

local function isTeamBasedMode(mode: string): boolean
	return mode == "Duo" or mode == "Squad" or mode == "Auto"
end

local function clearTeams()
	for _, team in activeTeams do
		team:Destroy()
	end
	activeTeams = {}
end

local function createTeam(): Team
	local team = Instance.new("Team")
	team.Name = "Team " .. (#activeTeams + 1)
	team.TeamColor = BrickColor.new(TEAM_COLORS[(#activeTeams % #TEAM_COLORS) + 1])
	team.AutoAssignable = false
	team.Parent = Teams
	table.insert(activeTeams, team)
	return team
end

-- targetSize болмаса (Auto) — әр отряд/жеке ойыншы өз алдына бөлек топ болады.
-- targetSize болса (Duo/Squad) — жартылай толған топтар бір-біріне толықтырылады.
local function regroupTeams(targetSize: number?)
	clearTeams()

	local assigned = {}
	local parties = {}

	for _, player in Players:GetPlayers() do
		if assigned[player] then
			continue
		end

		local party = { player }
		assigned[player] = true

		for _, mate in SquadService.GetSquadmates(player) do
			if not assigned[mate] and (not targetSize or #party < targetSize) then
				table.insert(party, mate)
				assigned[mate] = true
			end
		end

		table.insert(parties, party)
	end

	if not targetSize then
		for _, party in parties do
			local team = createTeam()
			for _, member in party do
				member.Team = team
			end
		end
		return
	end

	local team = createTeam()
	local size = 0

	for _, party in parties do
		if size > 0 and size + #party > targetSize then
			team = createTeam()
			size = 0
		end

		for _, member in party do
			member.Team = team
		end
		size += #party
	end
end

-- Матч ортасында жаңа ойыншы қосылғанда: барлық топты қайта құрмай, тек соны
-- ең қолайлы топқа (әуелі squadmates-і бар топқа, болмаса ең бос топқа) қосады.
local function assignNewPlayer(player: Player, targetSize: number?)
	for _, mate in SquadService.GetSquadmates(player) do
		if mate.Team and table.find(activeTeams, mate.Team) then
			player.Team = mate.Team
			return
		end
	end

	if not targetSize then
		player.Team = createTeam()
		return
	end

	local smallestTeam, smallestCount = nil, math.huge
	for _, team in activeTeams do
		local count = 0
		for _, otherPlayer in Players:GetPlayers() do
			if otherPlayer.Team == team then
				count += 1
			end
		end
		if count < targetSize and count < smallestCount then
			smallestTeam, smallestCount = team, count
		end
	end

	player.Team = smallestTeam or createTeam()
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

	if mode == currentMode then
		return true
	end

	currentMode = mode
	MatchModeChangedEvent:FireAllClients(currentMode)
	print("[MatchMode] Режим ауыстырылды: " .. mode)

	BossService.SetActive(mode == "Boss")
	DummyService.SetActive(mode == "Training")

	if isTeamBasedMode(mode) then
		regroupTeams(TEAM_SIZE[mode])
	else
		clearTeams()
		for _, player in Players:GetPlayers() do
			player.Team = nil :: any
		end
	end

	return true
end

function MatchModeService.Init()
	Players.PlayerAdded:Connect(function(player)
		MatchModeChangedEvent:FireClient(player, currentMode)

		if isTeamBasedMode(currentMode) then
			assignNewPlayer(player, TEAM_SIZE[currentMode])
		end
	end)

	SetMatchModeEvent.OnServerEvent:Connect(function(player, mode)
		if not AdminService.IsAdmin(player) or typeof(mode) ~= "string" then
			return
		end
		MatchModeService.SetMode(mode)
	end)
end

return MatchModeService
