local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PlayerDataService = require(script.Parent.PlayerDataService)
local NameplateService = require(script.Parent.NameplateService)
local HighlightService = require(script.Parent.HighlightService)

local DAMAGEABLE_TAG = "Damageable"
local BOSS_TAG = "Boss"
local BOSS_BASE_HEALTH = 350
local BOSS_HEALTH_PER_PLAYER = 150
local RESPAWN_DELAY = 60
local DEFEAT_XP_REWARD = 100
local DEFEAT_COIN_REWARD = 75
local ATTACK_RANGE = 10
local ATTACK_DAMAGE = 15
local ATTACK_COOLDOWN = 2
local AGGRO_RANGE = 45
local CHASE_TICK = 1
local WALK_SPEED = 10
local SAFE_RADIUS = 52

local BossSwingEvent = ReplicatedStorage.RemoteEvents:WaitForChild("BossSwing")
local AttackHitEvent = ReplicatedStorage.RemoteEvents:WaitForChild("AttackHit")

local BossService = {}

local activeBoss = nil :: { model: Model, humanoid: Humanoid }?
local desiredActive = false
local nextSpawnAllowedAt = 0

local function weldTo(base: BasePart, part: BasePart)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = base
	weld.Part1 = part
	weld.Parent = part
end

local function newPart(name: string, size: Vector3, material: Enum.Material, color: BrickColor, shape: Enum.PartType?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Material = material
	part.BrickColor = color
	part.CanCollide = false
	part.Massless = true
	if shape then
		part.Shape = shape
	end
	return part
end

local function newWedge(name: string, size: Vector3, material: Enum.Material, color: BrickColor): WedgePart
	local part = Instance.new("WedgePart")
	part.Name = name
	part.Size = size
	part.Material = material
	part.BrickColor = color
	part.CanCollide = false
	part.Massless = true
	return part
end

local function buildKatana(): Model
	local model = Instance.new("Model")
	model.Name = "BossKatana"

	local hilt = newPart("Hilt", Vector3.new(0.3, 1, 0.3), Enum.Material.Metal, BrickColor.new("Really black"))
	hilt.Parent = model
	model.PrimaryPart = hilt

	local guard = newPart("Guard", Vector3.new(1, 0.2, 0.3), Enum.Material.Metal, BrickColor.new("Really red"))
	guard.CFrame = hilt.CFrame * CFrame.new(0, hilt.Size.Y / 2 + guard.Size.Y / 2, 0)
	guard.Parent = model
	weldTo(hilt, guard)

	local blade = newPart("Blade", Vector3.new(0.18, 3.6, 0.6), Enum.Material.Metal, BrickColor.new("Black"))
	blade.CFrame = guard.CFrame * CFrame.new(0, guard.Size.Y / 2 + blade.Size.Y / 2, 0)
	blade.Parent = model
	weldTo(hilt, blade)

	local tip = newWedge("Tip", Vector3.new(0.6, 0.5, 0.18), Enum.Material.Metal, BrickColor.new("Black"))
	tip.CFrame = blade.CFrame * CFrame.new(0, blade.Size.Y / 2 + tip.Size.Y / 2, 0) * CFrame.Angles(0, 0, math.rad(-90))
	tip.Parent = model
	weldTo(hilt, tip)

	return model
end

local function buildBossBody(model: Model, rootPart: BasePart)
	-- Roblox дәстүрі бойынша HumanoidRootPart көрінбейтін/соқтықпайтын болуы керек;
	-- нақты дене мен соқтығысуды бөлек Torso бөлшегі көтереді (діріл/життер болмас үшін).
	rootPart.Transparency = 1
	rootPart.CanCollide = false

	local torso = newPart("Torso", rootPart.Size, Enum.Material.Slate, BrickColor.new("Really black"))
	torso.CanCollide = true
	torso.CFrame = rootPart.CFrame
	torso.Parent = model
	weldTo(rootPart, torso)

	local head = newPart("Head", Vector3.new(1.8, 1.6, 1.8), Enum.Material.Slate, BrickColor.new("Really black"))
	head.CFrame = rootPart.CFrame * CFrame.new(0, rootPart.Size.Y / 2 + head.Size.Y / 2, 0)
	head.Parent = model
	weldTo(rootPart, head)

	for _, xOffset in { -0.4, 0.4 } do
		local horn = newWedge("Horn", Vector3.new(0.25, 0.7, 0.4), Enum.Material.Metal, BrickColor.new("Really red"))
		horn.CFrame = head.CFrame
			* CFrame.new(xOffset, head.Size.Y / 2, -0.3)
			* CFrame.Angles(math.rad(-90), 0, math.rad(20 * (xOffset > 0 and 1 or -1)))
		horn.Parent = model
		weldTo(head, horn)
	end

	for _, xOffset in { -0.45, 0.45 } do
		local eye =
			newPart("Eye", Vector3.new(0.28, 0.28, 0.28), Enum.Material.Neon, BrickColor.new("Really red"), Enum.PartType.Ball)
		eye.CFrame = head.CFrame * CFrame.new(xOffset, 0.15, -head.Size.Z / 2)
		eye.Parent = model
		weldTo(head, eye)

		local glow = Instance.new("PointLight")
		glow.Color = Color3.fromRGB(255, 60, 60)
		glow.Range = 6
		glow.Brightness = 2
		glow.Parent = eye
	end

	local rightArm: BasePart
	for _, xOffset in { -2.3, 2.3 } do
		local pauldron = newPart("Pauldron", Vector3.new(1.2, 0.9, 1.2), Enum.Material.Neon, BrickColor.new("Really red"))
		pauldron.CFrame = rootPart.CFrame * CFrame.new(xOffset, rootPart.Size.Y / 2 - 0.5, 0)
		pauldron.Parent = model
		weldTo(rootPart, pauldron)

		local spike = newWedge("Spike", Vector3.new(0.4, 0.8, 0.4), Enum.Material.Metal, BrickColor.new("Really black"))
		spike.CFrame = pauldron.CFrame * CFrame.new(0, pauldron.Size.Y / 2, 0) * CFrame.Angles(math.rad(-90), 0, 0)
		spike.Parent = model
		weldTo(pauldron, spike)

		local arm = newPart("Arm", Vector3.new(0.55, 2.1, 0.55), Enum.Material.Slate, BrickColor.new("Really black"))
		arm.CFrame = rootPart.CFrame * CFrame.new(xOffset, rootPart.Size.Y / 2 - 1.9, 0)
		arm.Parent = model
		weldTo(rootPart, arm)

		if xOffset > 0 then
			rightArm = arm
		end
	end

	for _, xOffset in { -0.7, 0.7 } do
		local leg = newPart("Leg", Vector3.new(0.7, 2.2, 0.7), Enum.Material.Slate, BrickColor.new("Really black"))
		leg.CanCollide = true
		leg.CFrame = rootPart.CFrame * CFrame.new(xOffset, -(rootPart.Size.Y / 2) - 1.1, 0)
		leg.Parent = model
		weldTo(rootPart, leg)
	end

	local cape = newPart("Cape", Vector3.new(3, 3.6, 0.15), Enum.Material.Fabric, BrickColor.new("Maroon"))
	cape.CFrame = rootPart.CFrame * CFrame.new(0, -0.3, rootPart.Size.Z / 2 + 0.1) * CFrame.Angles(math.rad(8), 0, 0)
	cape.Parent = model
	weldTo(rootPart, cape)

	local katana = buildKatana()
	local hilt = katana.PrimaryPart :: BasePart
	local restC0 = CFrame.new(0, -(rightArm.Size.Y / 2) - (hilt.Size.Y / 2) - 0.1, 0)
	katana:PivotTo(rightArm.CFrame * restC0)
	katana.Parent = model

	local weaponMotor = Instance.new("Motor6D")
	weaponMotor.Name = "BossWeaponGrip"
	weaponMotor.Part0 = rightArm
	weaponMotor.Part1 = hilt
	weaponMotor.C0 = restC0
	weaponMotor.Parent = hilt
end

local function startMovementLoop(humanoid: Humanoid, rootPart: BasePart)
	task.spawn(function()
		while activeBoss and activeBoss.humanoid == humanoid and humanoid.Health > 0 do
			task.wait(CHASE_TICK)

			if not (activeBoss and activeBoss.humanoid == humanoid) or humanoid.Health <= 0 then
				break
			end

			local nearestRoot, nearestDistance = nil, AGGRO_RANGE

			for _, player in Players:GetPlayers() do
				local character = player.Character
				local targetRoot = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				local targetHumanoid = character and character:FindFirstChild("Humanoid") :: Humanoid?

				if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
					local distance = (targetRoot.Position - rootPart.Position).Magnitude
					if distance <= nearestDistance then
						nearestRoot = targetRoot
						nearestDistance = distance
					end
				end
			end

			if nearestRoot and nearestDistance > ATTACK_RANGE then
				local target = nearestRoot.Position
				local horizontalOffset = Vector3.new(target.X, 0, target.Z)

				if horizontalOffset.Magnitude > SAFE_RADIUS then
					local clamped = horizontalOffset.Unit * SAFE_RADIUS
					target = Vector3.new(clamped.X, target.Y, clamped.Z)
				end

				humanoid:MoveTo(target)
			else
				humanoid:MoveTo(rootPart.Position)
			end
		end
	end)
end

local function startAttackLoop(humanoid: Humanoid, rootPart: BasePart)
	task.spawn(function()
		while activeBoss and activeBoss.humanoid == humanoid and humanoid.Health > 0 do
			task.wait(ATTACK_COOLDOWN)

			if not (activeBoss and activeBoss.humanoid == humanoid) or humanoid.Health <= 0 then
				break
			end

			local closestCharacter, closestHumanoid, closestDistance = nil, nil, ATTACK_RANGE

			for _, player in Players:GetPlayers() do
				local character = player.Character
				local targetRoot = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				local targetHumanoid = character and character:FindFirstChild("Humanoid") :: Humanoid?

				if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
					local distance = (targetRoot.Position - rootPart.Position).Magnitude
					if distance <= closestDistance then
						closestCharacter = character
						closestHumanoid = targetHumanoid
						closestDistance = distance
					end
				end
			end

			if closestHumanoid then
				closestHumanoid:TakeDamage(ATTACK_DAMAGE)
				BossSwingEvent:FireAllClients()
				AttackHitEvent:FireAllClients(closestCharacter, ATTACK_DAMAGE)
			end
		end
	end)
end

local function despawnBoss(awardXP: boolean)
	if not activeBoss then
		return
	end

	local boss = activeBoss
	activeBoss = nil

	if awardXP then
		for _, player in Players:GetPlayers() do
			PlayerDataService.AddXP(player, DEFEAT_XP_REWARD)
			PlayerDataService.AddCoins(player, DEFEAT_COIN_REWARD)
		end
		print(string.format("[Boss] ArenaBoss жеңілді! Барлық ойыншыға +%d XP, +%d Coins.", DEFEAT_XP_REWARD, DEFEAT_COIN_REWARD))
		HighlightService.Log("Boss жеңілді", string.format("%d ойыншы бірігіп ArenaBoss-ты жеңді", #Players:GetPlayers()))
	end

	boss.model:Destroy()
end

local function spawnBoss()
	if activeBoss or os.clock() < nextSpawnAllowedAt then
		return
	end

	local model = Instance.new("Model")
	model.Name = "ArenaBoss"

	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(4, 5, 2.5)
	rootPart.Position = Vector3.new(-15, 8, 0)
	rootPart.Anchored = false
	rootPart.Parent = model

	buildBossBody(model, rootPart)

	local playerCount = math.max(1, #Players:GetPlayers())
	local maxHealth = BOSS_BASE_HEALTH + BOSS_HEALTH_PER_PLAYER * playerCount

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = maxHealth
	humanoid.Health = maxHealth
	humanoid.WalkSpeed = WALK_SPEED
	humanoid.Parent = model

	model.PrimaryPart = rootPart
	model.Parent = Workspace

	CollectionService:AddTag(model, DAMAGEABLE_TAG)
	CollectionService:AddTag(model, BOSS_TAG)

	NameplateService.Attach(rootPart, humanoid, "ARENA BOSS", Color3.fromRGB(230, 70, 70), 6)

	activeBoss = { model = model, humanoid = humanoid }
	startAttackLoop(humanoid, rootPart)
	startMovementLoop(humanoid, rootPart)
	print("[Boss] ArenaBoss пайда болды! Топтасып шабуыл жасаңыздар — өзі де соғады.")

	humanoid.Died:Connect(function()
		despawnBoss(true)
		nextSpawnAllowedAt = os.clock() + RESPAWN_DELAY

		task.wait(RESPAWN_DELAY)
		if desiredActive then
			spawnBoss()
		end
	end)
end

function BossService.TeleportTo(position: Vector3)
	if not activeBoss then
		return
	end

	local rootPart = activeBoss.model.PrimaryPart :: BasePart?
	if rootPart then
		rootPart.CFrame = CFrame.new(position + Vector3.new(-10, 5, 0))
	end
end

function BossService.SetActive(active: boolean)
	desiredActive = active

	if active then
		spawnBoss()
	else
		despawnBoss(false)
	end
end

function BossService.Init()
	-- Boss тек MatchModeService "Boss" режимін таңдағанда пайда болады, әдепкі бойынша жоқ.
end

return BossService
