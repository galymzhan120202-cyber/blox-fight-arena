local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NotificationService = require(script.Parent.NotificationService)

local MAX_SQUAD_SIZE = 4
local INVITE_EXPIRY = 30

local SquadInviteEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SquadInvite")
local SquadRespondEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SquadRespond")
local SquadLeaveEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SquadLeave")
local SquadUpdatedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SquadUpdated")
local SquadInviteReceivedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SquadInviteReceived")

local SquadService = {}

-- squadOf[player] барлық отряд мүшелері үшін БІРДЕЙ (ортақ) массивке сілтейді —
-- біреуін өзгерту барлығына бірден көрінеді.
local squadOf = {}
local pendingInvites = {} -- target Player -> { From = Player, ExpiresAt = number }

local function sendUpdate(player: Player)
	local squad = squadOf[player]
	local names = {}
	if squad then
		for _, member in squad do
			table.insert(names, member.Name)
		end
	end
	SquadUpdatedEvent:FireClient(player, names)
end

local function broadcastSquad(squad: { Player })
	for _, member in squad do
		sendUpdate(member)
	end
end

function SquadService.GetSquadmates(player: Player): { Player }
	local squad = squadOf[player]
	if not squad then
		return {}
	end

	local mates = {}
	for _, member in squad do
		if member ~= player then
			table.insert(mates, member)
		end
	end
	return mates
end

local function leaveSquad(player: Player)
	local squad = squadOf[player]
	if not squad then
		return
	end

	for index, member in squad do
		if member == player then
			table.remove(squad, index)
			break
		end
	end
	squadOf[player] = nil

	if #squad <= 1 then
		for _, member in squad do
			squadOf[member] = nil
			sendUpdate(member)
		end
	else
		broadcastSquad(squad)
	end

	sendUpdate(player)
end

local function joinSquad(player: Player, squadOwner: Player): boolean
	leaveSquad(player)

	local squad = squadOf[squadOwner]
	if not squad then
		squad = { squadOwner }
		squadOf[squadOwner] = squad
	end

	if #squad >= MAX_SQUAD_SIZE then
		return false
	end

	table.insert(squad, player)
	squadOf[player] = squad
	broadcastSquad(squad)

	return true
end

function SquadService.Init()
	SquadInviteEvent.OnServerEvent:Connect(function(player, targetName)
		if typeof(targetName) ~= "string" then
			return
		end

		local target = Players:FindFirstChild(targetName) :: Player?
		if not target or target == player then
			return
		end

		local squad = squadOf[player]
		if squad and #squad >= MAX_SQUAD_SIZE then
			NotificationService.Toast(
				player,
				string.format("Отряд толы (макс %d)", MAX_SQUAD_SIZE),
				Color3.fromRGB(220, 80, 80)
			)
			return
		end

		pendingInvites[target] = { From = player, ExpiresAt = os.clock() + INVITE_EXPIRY }
		SquadInviteReceivedEvent:FireClient(target, player.Name)
		NotificationService.Toast(
			player,
			string.format("%s ойыншысына шақыру жіберілді", target.Name),
			Color3.fromRGB(120, 220, 140)
		)

		task.delay(INVITE_EXPIRY, function()
			local invite = pendingInvites[target]
			if invite and invite.From == player then
				pendingInvites[target] = nil
			end
		end)
	end)

	SquadRespondEvent.OnServerEvent:Connect(function(player, accepted)
		local invite = pendingInvites[player]
		if not invite then
			return
		end
		pendingInvites[player] = nil

		if accepted ~= true or invite.ExpiresAt < os.clock() or not invite.From.Parent then
			return
		end

		if not joinSquad(player, invite.From) then
			NotificationService.Toast(player, "Отряд толы", Color3.fromRGB(220, 80, 80))
		end
	end)

	SquadLeaveEvent.OnServerEvent:Connect(function(player)
		leaveSquad(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		leaveSquad(player)
		pendingInvites[player] = nil
	end)
end

return SquadService
