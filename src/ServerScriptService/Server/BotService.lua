local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local NameplateService = require(script.Parent.NameplateService)
local AdminService = require(script.Parent.AdminService)
local RoundService = require(script.Parent.RoundService)

local DAMAGEABLE_TAG = "Damageable"
local BOT_TAG = "Bot"
local MAX_BOTS = 3
local BOT_MAX_HEALTH = 100
local BOT_WALK_SPEED = 14
local AGGRO_RANGE = 50
local ATTACK_RANGE = 7
local ATTACK_DAMAGE = 12
local ATTACK_COOLDOWN = 1.5
local CHASE_TICK = 1
local RESPAWN_DELAY = 5
local SAFE_RADIUS = 45

local BOT_COLORS = {
	BrickColor.new("Bright blue"),
	BrickColor.new("Bright green"),
	BrickColor.new("Bright violet"),
}

local AttackHitEvent = ReplicatedStorage.RemoteEvents:WaitForChild("AttackHit")
local SetBotCountEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SetBotCount")
local BotCountChangedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("BotCountChanged")

local BotService = {}

local activeBots = {}
local desiredBotCount = 0

local function weldTo(base: BasePart, part: BasePart)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = base
	weld.Part1 = part
	weld.Parent = part
end

local function newPart(name: string, size: Vector3, color: BrickColor, canCollide: boolean): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.BrickColor = color
	part.CanCollide = canCollide
	part.Material = Enum.Material.SmoothPlastic
	return part
end

local function buildSwordProp(rightArm: BasePart)
	local sword = Instance.new("Model")
	sword.Name = "BotSword"

	local hilt = newPart("Hilt", Vector3.new(0.25, 0.8, 0.25), BrickColor.new("Really black"), false)
	hilt.Massless = true
	hilt.Parent = sword
	sword.PrimaryPart = hilt

	local blade = newPart("Blade", Vector3.new(0.15, 2.2, 0.5), BrickColor.new("Institutional white"), false)
	blade.Massless = true
	blade.Material = Enum.Material.Metal
	blade.CFrame = hilt.CFrame * CFrame.new(0, hilt.Size.Y / 2 + blade.Size.Y / 2, 0)
	blade.Parent = sword
	weldTo(hilt, blade)

	local restC0 = CFrame.new(0.1, -0.3, -0.2) * CFrame.Angles(math.rad(60), 0, 0)
	sword:PivotTo(rightArm.CFrame * restC0)
	sword.Parent = rightArm.Parent

	local motor = Instance.new("Motor6D")
	motor.Name = "BotWeaponGrip"
	motor.Part0 = rightArm
	motor.Part1 = hilt
	motor.C0 = restC0
	motor.Parent = hilt
end

local function findNearestPlayer(fromPosition: Vector3, maxRange: number)
	local nearestPlayer, nearestRoot, nearestHumanoid, nearestDistance = nil, nil, nil, maxRange

	for _, player in Players:GetPlayers() do
		local character = player.Character
		local targetRoot = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local targetHumanoid = character and character:FindFirstChild("Humanoid") :: Humanoid?

		if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
			local distance = (targetRoot.Position - fromPosition).Magnitude
			if distance <= nearestDistance then
				nearestPlayer, nearestRoot, nearestHumanoid, nearestDistance = player, targetRoot, targetHumanoid, distance
			end
		end
	end

	return nearestPlayer, nearestRoot, nearestHumanoid, nearestDistance
end

local function despawnBot(bot)
	if activeBots[bot.id] ~= bot then
		return
	end

	activeBots[bot.id] = nil
	bot.model:Destroy()
end

local spawnBot

spawnBot = function(id: number)
	if activeBots[id] then
		return
	end

	local color = BOT_COLORS[((id - 1) % #BOT_COLORS) + 1]

	local model = Instance.new("Model")
	model.Name = "CombatBot" .. id

	local rootPart = newPart("HumanoidRootPart", Vector3.new(2, 2, 1), color, false)
	rootPart.Position = Vector3.new(math.random(-10, 10), 8, math.random(-10, 10))
	rootPart.Anchored = false
	rootPart.Parent = model

	local torso = newPart("Torso", Vector3.new(2, 2, 1), color, true)
	torso.CFrame = rootPart.CFrame
	torso.Parent = model
	weldTo(rootPart, torso)

	local head = newPart("Head", Vector3.new(1.2, 1.2, 1.2), color, false)
	head.CFrame = rootPart.CFrame * CFrame.new(0, rootPart.Size.Y / 2 + head.Size.Y / 2, 0)
	head.Parent = model
	weldTo(rootPart, head)

	local rightArm = newPart("Right Arm", Vector3.new(0.6, 1.8, 0.6), color, false)
	rightArm.CFrame = rootPart.CFrame * CFrame.new(rootPart.Size.X / 2 + 0.3, 0.2, 0)
	rightArm.Parent = model
	weldTo(rootPart, rightArm)

	local leftArm = newPart("Left Arm", Vector3.new(0.6, 1.8, 0.6), color, false)
	leftArm.CFrame = rootPart.CFrame * CFrame.new(-(rootPart.Size.X / 2 + 0.3), 0.2, 0)
	leftArm.Parent = model
	weldTo(rootPart, leftArm)

	for _, xOffset in { -0.5, 0.5 } do
		local leg = newPart("Leg", Vector3.new(0.6, 2, 0.6), BrickColor.new("Really black"), true)
		leg.CFrame = rootPart.CFrame * CFrame.new(xOffset, -(rootPart.Size.Y / 2) - 1, 0)
		leg.Parent = model
		weldTo(rootPart, leg)
	end

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = BOT_MAX_HEALTH
	humanoid.Health = BOT_MAX_HEALTH
	humanoid.WalkSpeed = BOT_WALK_SPEED
	humanoid.Parent = model

	model.PrimaryPart = rootPart
	model.Parent = Workspace

	CollectionService:AddTag(model, DAMAGEABLE_TAG)
	CollectionService:AddTag(model, BOT_TAG)

	buildSwordProp(rightArm)
	NameplateService.Attach(rootPart, humanoid, "Bot", Color3.fromRGB(120, 170, 255), 3.2)

	local bot = { id = id, model = model, humanoid = humanoid, rootPart = rootPart }
	activeBots[id] = bot

	task.spawn(function()
		while activeBots[id] == bot and humanoid.Health > 0 do
			task.wait(CHASE_TICK)
			if activeBots[id] ~= bot or humanoid.Health <= 0 then
				break
			end

			if not RoundService.IsActive() then
				humanoid:MoveTo(rootPart.Position)
				continue
			end

			local _, nearestRoot, _, nearestDistance = findNearestPlayer(rootPart.Position, AGGRO_RANGE)

			if nearestRoot and nearestDistance > ATTACK_RANGE then
				local target = nearestRoot.Position
				local flat = Vector3.new(target.X, 0, target.Z)
				if flat.Magnitude > SAFE_RADIUS then
					local clamped = flat.Unit * SAFE_RADIUS
					target = Vector3.new(clamped.X, target.Y, clamped.Z)
				end
				humanoid:MoveTo(target)
			else
				humanoid:MoveTo(rootPart.Position)
			end
		end
	end)

	task.spawn(function()
		while activeBots[id] == bot and humanoid.Health > 0 do
			task.wait(ATTACK_COOLDOWN)
			if activeBots[id] ~= bot or humanoid.Health <= 0 then
				break
			end

			if not RoundService.IsActive() then
				continue
			end

			local _, targetRoot, targetHumanoid, distance = findNearestPlayer(rootPart.Position, ATTACK_RANGE)
			if targetRoot and targetHumanoid then
				targetHumanoid:TakeDamage(ATTACK_DAMAGE)
				AttackHitEvent:FireAllClients(targetHumanoid.Parent, ATTACK_DAMAGE)
			end
		end
	end)

	humanoid.Died:Connect(function()
		despawnBot(bot)

		task.wait(RESPAWN_DELAY)
		if desiredBotCount >= id then
			spawnBot(id)
		end
	end)
end

function BotService.GetCount(): number
	return desiredBotCount
end

function BotService.SetCount(count: number)
	count = math.clamp(count, 0, MAX_BOTS)
	desiredBotCount = count

	for id = 1, MAX_BOTS do
		if id <= count and not activeBots[id] then
			spawnBot(id)
		elseif id > count and activeBots[id] then
			despawnBot(activeBots[id])
		end
	end

	BotCountChangedEvent:FireAllClients(count)
	print(string.format("[Bot] Бот саны: %d", count))
end

function BotService.Init()
	RoundService.SetBotCountProvider(BotService.GetCount)

	Players.PlayerAdded:Connect(function(player)
		BotCountChangedEvent:FireClient(player, desiredBotCount)
	end)

	SetBotCountEvent.OnServerEvent:Connect(function(player, count)
		if AdminService.IsAdmin(player) and typeof(count) == "number" then
			BotService.SetCount(count)
		end
	end)
end

return BotService
