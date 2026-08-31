local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local NameplateService = require(script.Parent.NameplateService)
local AdminService = require(script.Parent.AdminService)
local RoundService = require(script.Parent.RoundService)
local NotificationService = require(script.Parent.NotificationService)
local HighlightService = require(script.Parent.HighlightService)
local WeaponModelService = require(script.Parent.WeaponModelService)

local ClassDefinitions = require(ReplicatedStorage.Modules.Classes.ClassDefinitions)
local WeaponDatabase = require(ReplicatedStorage.Modules.Data.WeaponDatabase)

local DAMAGEABLE_TAG = "Damageable"
local BOT_TAG = "Bot"

local MAX_BOTS = 6
local BOT_RUN_BONUS = 4 -- қуғанда WalkSpeed үстіне
local AGGRO_RANGE = 95
local PLAYER_PRIORITY_RANGE = 55
local AI_TICK = 0.18
local RESPAWN_DELAY = 4
local SAFE_RADIUS = 46
local RETREAT_HP_FRAC = 0.22
local RETREAT_UNTIL_HP_FRAC = 0.5
local FOCUS_HP_FRAC = 0.32 -- осыдан төмен HP жауды бәрі "бірге қуады" (драмалық финиш)
local KNOCKBACK_FORCE = 34
local KNOCKBACK_UP = 8
local STRAFE_FLIP_INTERVAL = 1.3
local KILL_CREDIT_WINDOW = 5
local COMBO_HITS = 2 -- жақынтабан бір "шабуылда" неше рет сермейді
local COMBO_GAP = 0.24

-- R15 әдепкі анимациялар + әдепкі құрал (Tool) шабуыл анимациялары (ашық).
local LOCO_ANIM_IDS = {
	idle = "rbxassetid://507766666",
	walk = "rbxassetid://507777826",
	run = "rbxassetid://507767714",
}
local ATTACK_ANIM_IDS = {
	slash = "rbxassetid://522635514", -- ToolSlash R15
	lunge = "rbxassetid://522638767", -- ToolLunge R15
}

-- Roblox-пен бірге келетін бөлшек текстуралары (әрдайым бар).
local TEX_SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local TEX_SMOKE = "rbxasset://textures/particles/smoke_main.dds"

local KILLSTREAK_MESSAGES = {
	[3] = "ҮШТІК ЖЕҢІС",
	[5] = "БЕСТІК ШАБУЫЛ",
	[7] = "ТОҚТАТЫЛМАЙДЫ",
	[10] = "ЛЕГЕНДА",
}

-- name + class (ClassDefinitions) + weapon (WeaponDatabase) + рең.
local BOT_PROFILES = {
	{ name = "Ронин", class = "Warrior", weapon = "Sword", tint = Color3.fromRGB(70, 130, 240) },
	{ name = "Мерген", class = "Archer", weapon = "Bow", tint = Color3.fromRGB(90, 200, 120) },
	{ name = "Архимаг", class = "Mage", weapon = "Staff", tint = Color3.fromRGB(180, 110, 240) },
	{ name = "Көлеңке", class = "Assassin", weapon = "Daggers", tint = Color3.fromRGB(230, 80, 90) },
	{ name = "Балғашы", class = "Warrior", weapon = "Hammer", tint = Color3.fromRGB(240, 170, 60) },
	{ name = "Найзагер", class = "Warrior", weapon = "Spear", tint = Color3.fromRGB(70, 210, 220) },
}

local AttackHitEvent = ReplicatedStorage.RemoteEvents:WaitForChild("AttackHit")
local SetBotCountEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SetBotCount")
local BotCountChangedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("BotCountChanged")

local BotService = {}

local activeBots = {}
local spawning = {}
local desiredBotCount = 0

local botStreaks = {}
local botLastKilledBy = {}
local botFirstBlood = false

local function resetHighlightState()
	botStreaks = {}
	botLastKilledBy = {}
	botFirstBlood = false
end

local function weaponKind(weaponName: string): string
	if weaponName == "Bow" then
		return "ranged"
	elseif weaponName == "Staff" then
		return "magic"
	end
	return "melee"
end

--------------------------------------------------------------------------------
-- Риг + қару
--------------------------------------------------------------------------------

local function buildDescription(tint: Color3): HumanoidDescription
	local desc = Instance.new("HumanoidDescription")
	desc.HeadColor = tint
	desc.TorsoColor = tint
	desc.LeftArmColor = tint
	desc.RightArmColor = tint
	desc.LeftLegColor = tint:Lerp(Color3.new(0, 0, 0), 0.55)
	desc.RightLegColor = tint:Lerp(Color3.new(0, 0, 0), 0.55)
	return desc
end

local function buildBlockRig(tint: Color3): Model
	local model = Instance.new("Model")
	local color = BrickColor.new(tint)

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.BrickColor = color
	root.Parent = model

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.BrickColor = color
	torso.CFrame = root.CFrame
	torso.Parent = model
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1 = root, torso
	weld.Parent = torso

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.BrickColor = color
	head.CFrame = root.CFrame * CFrame.new(0, 1.6, 0)
	head.Parent = model
	local hweld = Instance.new("WeldConstraint")
	hweld.Part0, hweld.Part1 = root, head
	hweld.Parent = head

	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = model

	model.PrimaryPart = root
	return model
end

local function createRig(profile): (Model, Humanoid, BasePart)
	local classDef = ClassDefinitions.Get(profile.class) or { MaxHealth = 110, WalkSpeed = 16 }

	local model: Model?
	local ok, result = pcall(function()
		return Players:CreateHumanoidModelFromDescription(buildDescription(profile.tint), Enum.HumanoidRigType.R15)
	end)

	if ok and result then
		model = result
	else
		warn("[Bot] CreateHumanoidModelFromDescription сәтсіз, резерв риг: " .. tostring(result))
		model = buildBlockRig(profile.tint)
	end
	assert(model)

	model.Name = "CombatBot_" .. profile.name

	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid.MaxHealth = classDef.MaxHealth
	humanoid.Health = classDef.MaxHealth
	humanoid.WalkSpeed = classDef.WalkSpeed
	humanoid.AutoRotate = true
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.BreakJointsOnDeath = true

	local rootPart = model:FindFirstChild("HumanoidRootPart") :: BasePart
	return model, humanoid, rootPart
end

-- Қаруды қолға Motor6D-мен дәнекерлеп, "сермеу" үшін моторды қайтарады.
local function attachWeapon(model: Model, weaponName: string, tint: Color3): Motor6D?
	local hand = (model:FindFirstChild("RightHand") or model:FindFirstChild("Right Arm")) :: BasePart?
	if not hand then
		return nil
	end

	local weaponModel = WeaponModelService.BuildDetached(weaponName)
	if not weaponModel then
		return nil
	end

	local grip = weaponModel.PrimaryPart :: BasePart
	local baseC0 = CFrame.new(0, -0.15, -0.45) * CFrame.Angles(math.rad(-95), 0, 0)
	weaponModel:PivotTo(hand.CFrame * baseC0)
	weaponModel.Parent = model

	local motor = Instance.new("Motor6D")
	motor.Name = "BotWeaponGrip"
	motor.Part0 = hand
	motor.Part1 = grip
	motor.C0 = baseC0
	motor:SetAttribute("Rest", true)
	motor.Parent = grip

	-- Жақынтабан қаруға жарқыл ізі (Trail).
	if weaponKind(weaponName) == "melee" then
		local blade = weaponModel:FindFirstChild("Blade") or weaponModel:FindFirstChild("Head") or grip
		if blade and blade:IsA("BasePart") then
			local a0 = Instance.new("Attachment")
			a0.Position = Vector3.new(0, blade.Size.Y / 2, 0)
			a0.Parent = blade
			local a1 = Instance.new("Attachment")
			a1.Position = Vector3.new(0, -blade.Size.Y / 2, 0)
			a1.Parent = blade

			local trail = Instance.new("Trail")
			trail.Attachment0 = a0
			trail.Attachment1 = a1
			trail.Lifetime = 0.18
			trail.MinLength = 0.05
			trail.LightEmission = 1
			trail.Color = ColorSequence.new(tint:Lerp(Color3.new(1, 1, 1), 0.6))
			trail.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.2),
				NumberSequenceKeypoint.new(1, 1),
			})
			trail.Enabled = false
			trail.Parent = blade
		end
	end

	return motor
end

--------------------------------------------------------------------------------
-- Анимация
--------------------------------------------------------------------------------

local function loadTracks(animator: Animator, ids: { [string]: string }): { [string]: AnimationTrack }
	local tracks = {}
	for key, id in ids do
		local anim = Instance.new("Animation")
		anim.AnimationId = id
		local ok, track = pcall(function()
			return animator:LoadAnimation(anim)
		end)
		if ok and track then
			tracks[key] = track
		end
	end
	return tracks
end

-- Локомоция күйін басқарады әрі шабуыл анимациясын ойнататын функция қайтарады.
local function setupBotAnims(humanoid: Humanoid): (kind: string) -> ()
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local loco = loadTracks(animator, LOCO_ANIM_IDS)
	local atk = loadTracks(animator, ATTACK_ANIM_IDS)
	for _, track in atk do
		track.Priority = Enum.AnimationPriority.Action
	end

	local current: AnimationTrack? = nil
	local function play(key: string)
		local track = loco[key]
		if not track or current == track then
			return
		end
		if current then
			current:Stop(0.2)
		end
		current = track
		track:Play(0.2)
	end

	humanoid.Running:Connect(function(speed)
		if humanoid.Health <= 0 then
			return
		end
		if speed > humanoid.WalkSpeed + 2 then
			play("run")
		elseif speed > 0.5 then
			play("walk")
		else
			play("idle")
		end
	end)
	play("idle")

	return function(kind: string)
		local track = (kind == "melee") and (math.random() < 0.5 and atk.slash or atk.lunge) or atk.lunge
		if track then
			track:Play(0.08)
		end
	end
end

-- Motor6D C0-ды тербетіп "шабуыл" қимылын жасайды (BossService секілді).
local function swingWeapon(motor: Motor6D?, kind: string)
	if not motor then
		return
	end
	local rest = motor.C0

	local out, back
	if kind == "ranged" then
		out = rest * CFrame.new(0, 0, 0.4)
		back = rest
	elseif kind == "magic" then
		out = rest * CFrame.Angles(math.rad(35), 0, 0)
		back = rest
	else
		out = rest * CFrame.Angles(math.rad(-95), 0, math.rad(15))
		back = rest
	end

	local weaponModel = motor.Part1 and motor.Part1.Parent
	local trail = weaponModel and weaponModel:FindFirstChildWhichIsA("Trail", true)
	if trail then
		trail.Enabled = true
	end

	local t1 = TweenService:Create(motor, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { C0 = out })
	t1.Completed:Connect(function()
		TweenService:Create(motor, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { C0 = back }):Play()
		if trail then
			task.delay(0.16, function()
				trail.Enabled = false
			end)
		end
	end)
	t1:Play()
end

--------------------------------------------------------------------------------
-- Снаряд (садақ/сиқыр) — тек көрнекі, зақым hitscan
--------------------------------------------------------------------------------

local function fireProjectile(fromPos: Vector3, toPos: Vector3, kind: string, tint: Color3)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Material = Enum.Material.Neon
	part.CFrame = CFrame.new(fromPos, toPos)

	if kind == "magic" then
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(1.1, 1.1, 1.1)
		part.Color = tint
	else
		part.Size = Vector3.new(0.14, 0.14, 2.4)
		part.Color = Color3.fromRGB(210, 180, 140)
	end
	part.Parent = Workspace

	local light = Instance.new("PointLight")
	light.Color = part.Color
	light.Range = 8
	light.Brightness = 2
	light.Parent = part

	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 0, 0.5)
	a0.Parent = part
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, 0, -0.5)
	a1.Parent = part
	local streak = Instance.new("Trail")
	streak.Attachment0 = a0
	streak.Attachment1 = a1
	streak.Lifetime = kind == "magic" and 0.35 or 0.22
	streak.LightEmission = 1
	streak.Color = ColorSequence.new(part.Color)
	streak.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	streak.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, kind == "magic" and 1.6 or 0.7),
		NumberSequenceKeypoint.new(1, 0),
	})
	streak.Parent = part

	local dir = (toPos - fromPos)
	local dist = math.min(dir.Magnitude, 120)
	local speed = kind == "magic" and 70 or 140
	local travelTime = dist / speed

	local goal = CFrame.new(fromPos + dir.Unit * dist, toPos)
	local tween = TweenService:Create(part, TweenInfo.new(travelTime, Enum.EasingStyle.Linear), { CFrame = goal })
	tween.Completed:Connect(function()
		local flash = TweenService:Create(part, TweenInfo.new(0.12), { Size = part.Size * 2, Transparency = 1 })
		flash.Completed:Connect(function()
			part:Destroy()
		end)
		flash:Play()
	end)
	tween:Play()
end

--------------------------------------------------------------------------------
-- Нысана таңдау
--------------------------------------------------------------------------------

local function livingRoot(character: Instance?): (BasePart?, Humanoid?)
	if not character then
		return nil, nil
	end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if root and humanoid and humanoid.Health > 0 then
		return root, humanoid
	end
	return nil, nil
end

local function pickTarget(bot)
	local fromPos = bot.rootPart.Position

	-- Ойыншы жақын болса — оған.
	local bestPlayerRoot, bestPlayerHum, bestPlayerDist = nil, nil, PLAYER_PRIORITY_RANGE
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("Cinematic") then
			continue
		end
		local root, humanoid = livingRoot(player.Character)
		if root and humanoid then
			local dist = (root.Position - fromPos).Magnitude
			if dist <= bestPlayerDist then
				bestPlayerRoot, bestPlayerHum, bestPlayerDist = root, humanoid, dist
			end
		end
	end
	if bestPlayerRoot then
		return bestPlayerRoot, bestPlayerHum, bestPlayerDist, nil
	end

	-- Әйтпесе — боттар. HP-ы FOCUS_HP_FRAC-тан төмен жау болса, соны бәрі қуады.
	local nearestBot, nearestRoot, nearestHum, nearestDist = nil, nil, nil, AGGRO_RANGE
	local woundedBot, woundedRoot, woundedHum, woundedDist = nil, nil, nil, AGGRO_RANGE * 1.4
	for _, other in activeBots do
		if other ~= bot and other.humanoid.Health > 0 then
			local dist = (other.rootPart.Position - fromPos).Magnitude
			if dist <= nearestDist then
				nearestBot, nearestRoot, nearestHum, nearestDist = other, other.rootPart, other.humanoid, dist
			end
			if
				other.humanoid.Health / other.humanoid.MaxHealth < FOCUS_HP_FRAC
				and dist <= woundedDist
			then
				woundedBot, woundedRoot, woundedHum, woundedDist = other, other.rootPart, other.humanoid, dist
			end
		end
	end

	if woundedBot then
		return woundedRoot, woundedHum, woundedDist, woundedBot
	end
	return nearestRoot, nearestHum, nearestDist, nearestBot
end

--------------------------------------------------------------------------------
-- Бот өмір циклі
--------------------------------------------------------------------------------

local spawnBot

local function despawnBot(bot)
	if activeBots[bot.id] ~= bot then
		return
	end
	activeBots[bot.id] = nil
	if bot.model.Parent then
		bot.model:Destroy()
	end
end

local function clampToArena(pos: Vector3): Vector3
	local flat = Vector3.new(pos.X, 0, pos.Z)
	if flat.Magnitude > SAFE_RADIUS then
		local clamped = flat.Unit * SAFE_RADIUS
		return Vector3.new(clamped.X, pos.Y, clamped.Z)
	end
	return pos
end

local function faceTarget(bot, targetPos: Vector3)
	local rootPart = bot.rootPart
	local flat = Vector3.new(targetPos.X, rootPart.Position.Y, targetPos.Z)
	if (flat - rootPart.Position).Magnitude < 0.1 then
		return
	end
	rootPart.CFrame = CFrame.lookAt(rootPart.Position, flat)
end

-- Қысқа өмірлі бөлшек-жарылыс (Attachment + ParticleEmitter, :Emit).
local function burstAt(position: Vector3, count: number, tint: Color3, texture: string, spd: number, life: number, sizeN: number)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.CFrame = CFrame.new(position)
	anchor.Parent = Workspace

	local att = Instance.new("Attachment")
	att.Parent = anchor

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = texture
	emitter.Color = ColorSequence.new(tint)
	emitter.LightEmission = 0.8
	emitter.Lifetime = NumberRange.new(life * 0.6, life)
	emitter.Speed = NumberRange.new(spd * 0.4, spd)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, sizeN),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Drag = 3
	emitter.Enabled = false
	emitter.Parent = att

	emitter:Emit(count)
	task.delay(life + 0.5, function()
		anchor:Destroy()
	end)
end

local function spawnFlash(model: Model, rootPart: BasePart, tint: Color3)
	burstAt(rootPart.Position, 22, tint, TEX_SPARK, 26, 0.5, 2)

	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part.Transparency < 1 then
			local original = part.Transparency
			part.Transparency = 1
			TweenService:Create(part, TweenInfo.new(0.3), { Transparency = original }):Play()
		end
	end
end

local function deathPoof(rootPart: BasePart, tint: Color3)
	burstAt(rootPart.Position, 26, tint, TEX_SPARK, 40, 0.55, 2.4)
	burstAt(rootPart.Position, 14, Color3.fromRGB(40, 40, 45), TEX_SMOKE, 12, 0.9, 5)
end

local function handleBotKill(killer, victim)
	killer.kills += 1

	local extra = { killer = killer.model, victim = victim.model }

	if not botFirstBlood then
		botFirstBlood = true
		NotificationService.ToastAll(string.format("АЛҒАШҚЫ ҚАН — %s!", killer.name), Color3.fromRGB(255, 90, 90))
		HighlightService.Log("Алғашқы қан", string.format("%s алғашқы өлтіруді жасады", killer.name), extra)
	end

	if botLastKilledBy[killer.name] == victim.name then
		NotificationService.ToastAll(string.format("%s КЕК АЛДЫ!", killer.name), Color3.fromRGB(200, 120, 255))
		HighlightService.Log("Кек", string.format("%s → %s кегін алды", killer.name, victim.name), extra)
	end
	botLastKilledBy[victim.name] = killer.name

	botStreaks[victim.name] = 0
	local streak = (botStreaks[killer.name] or 0) + 1
	botStreaks[killer.name] = streak

	NotificationService.Feed(string.format("%s ➤ %s", killer.name, victim.name))

	local msg = KILLSTREAK_MESSAGES[streak]
	if msg then
		NotificationService.ToastAll(string.format("%s — %s (%dx)!", killer.name, msg, streak), Color3.fromRGB(255, 200, 60))
		HighlightService.Log("Killstreak", string.format("%s — %s (%dx)", killer.name, msg, streak), extra)
	elseif streak >= 2 then
		-- Қатарынан 2+ өлтіру — титрсіз болса да клипке тұрарлық "double"
		HighlightService.Log("Дубль", string.format("%s қатарынан %d өлтірді", killer.name, streak), extra)
	end
end

spawnBot = function(id: number)
	if activeBots[id] or spawning[id] then
		return
	end
	spawning[id] = true

	local profile = BOT_PROFILES[((id - 1) % #BOT_PROFILES) + 1]
	local weapon = WeaponDatabase[profile.weapon]
	local kind = weaponKind(profile.weapon)
	local baseSpeed = (ClassDefinitions.Get(profile.class) or { WalkSpeed = 16 }).WalkSpeed
	local model, humanoid, rootPart = createRig(profile)

	if desiredBotCount < id then
		spawning[id] = nil
		model:Destroy()
		return
	end

	local angle = math.rad((360 / MAX_BOTS) * id + math.random(-25, 25))
	local radius = math.random(24, 40)
	model:PivotTo(CFrame.new(math.cos(angle) * radius, 6, math.sin(angle) * radius))
	model.Parent = Workspace

	CollectionService:AddTag(model, DAMAGEABLE_TAG)
	CollectionService:AddTag(model, BOT_TAG)

	local weaponMotor = attachWeapon(model, profile.weapon, profile.tint)
	NameplateService.Attach(rootPart, humanoid, string.format("%s · %s", profile.name, profile.class), profile.tint, 3.4)
	local playAttack = setupBotAnims(humanoid)
	spawnFlash(model, rootPart, profile.tint)

	local bot = {
		id = id,
		name = profile.name,
		tint = profile.tint,
		kind = kind,
		range = weapon.Range,
		damage = weapon.Damage,
		cooldown = weapon.Cooldown,
		baseSpeed = baseSpeed,
		model = model,
		humanoid = humanoid,
		rootPart = rootPart,
		weaponMotor = weaponMotor,
		playAttack = playAttack,
		kills = 0,
		lastHitByBot = nil,
		lastHitByBotAt = 0,
		strafeDir = 1,
		strafeFlipAt = 0,
	}
	activeBots[id] = bot
	spawning[id] = nil

	-- Қозғалыс / AI
	task.spawn(function()
		while activeBots[id] == bot and humanoid.Health > 0 do
			task.wait(AI_TICK)
			if activeBots[id] ~= bot or humanoid.Health <= 0 then
				break
			end

			if not RoundService.IsActive() then
				humanoid.AutoRotate = true
				humanoid:Move(Vector3.zero)
				continue
			end

			local targetRoot, _, targetDist = pickTarget(bot)
			if not targetRoot then
				humanoid.AutoRotate = true
				humanoid:Move(Vector3.zero)
				continue
			end

			local hpFrac = humanoid.Health / humanoid.MaxHealth
			bot.retreating = bot.retreating and hpFrac < RETREAT_UNTIL_HP_FRAC or hpFrac < RETREAT_HP_FRAC

			local runSpeed = humanoid.WalkSpeed + BOT_RUN_BONUS
			local ranged = bot.kind ~= "melee"
			-- Қалаған қашықтық: жақынтабан → 0; қашықтан соғатын → Range*0.8
			local desired = ranged and bot.range * 0.8 or 0

			if bot.retreating then
				humanoid.AutoRotate = true
				humanoid.WalkSpeed = runSpeed
				local away = rootPart.Position - targetRoot.Position
				away = Vector3.new(away.X, 0, away.Z)
				away = away.Magnitude > 0 and away.Unit or Vector3.new(0, 0, 1)
				humanoid:MoveTo(clampToArena(rootPart.Position + away * 12))
			elseif ranged and targetDist < desired * 0.7 then
				-- Тым жақын — кейін шегініп ату қашықтығын сақтау (kite)
				humanoid.AutoRotate = false
				faceTarget(bot, targetRoot.Position)
				humanoid.WalkSpeed = runSpeed
				local away = rootPart.Position - targetRoot.Position
				away = Vector3.new(away.X, 0, away.Z).Unit
				humanoid:MoveTo(clampToArena(rootPart.Position + away * 10))
			elseif targetDist > math.max(bot.range * 0.9, desired) then
				humanoid.AutoRotate = true
				humanoid.WalkSpeed = runSpeed
				humanoid:MoveTo(clampToArena(targetRoot.Position))
			else
				-- Қажетті қашықтықтамыз — жауға қарап айнала басу
				humanoid.AutoRotate = false
				faceTarget(bot, targetRoot.Position)
				humanoid.WalkSpeed = bot.baseSpeed
				if os.clock() >= bot.strafeFlipAt then
					bot.strafeDir = -bot.strafeDir
					bot.strafeFlipAt = os.clock() + STRAFE_FLIP_INTERVAL + math.random() * 0.8
				end
				local toTarget = targetRoot.Position - rootPart.Position
				toTarget = Vector3.new(toTarget.X, 0, toTarget.Z)
				if toTarget.Magnitude > 0 then
					local side = Vector3.new(-toTarget.Z, 0, toTarget.X).Unit * bot.strafeDir
					humanoid:MoveTo(clampToArena(rootPart.Position + side * 5))
				end
			end
		end
	end)

	-- Шабуыл
	task.spawn(function()
		while activeBots[id] == bot and humanoid.Health > 0 do
			task.wait(bot.cooldown * (0.85 + math.random() * 0.3))
			if activeBots[id] ~= bot or humanoid.Health <= 0 then
				break
			end
			if not RoundService.IsActive() or bot.retreating then
				continue
			end

			local targetRoot, targetHum, targetDist, targetBot = pickTarget(bot)
			if not (targetRoot and targetHum) or targetDist > bot.range then
				continue
			end

			local toTarget = targetRoot.Position - rootPart.Position
			if toTarget.Magnitude > 0 and rootPart.CFrame.LookVector:Dot(toTarget.Unit) < 0.3 then
				continue
			end

			-- Windup: аяғын нық қойып, дене серпінін берсін (сырғанамасын)
			humanoid.AutoRotate = false
			faceTarget(bot, targetRoot.Position)
			humanoid.WalkSpeed = 0
			task.wait(0.12)
			humanoid.WalkSpeed = bot.baseSpeed
			if activeBots[id] ~= bot or humanoid.Health <= 0 then
				break
			end

			local hits = bot.kind == "melee" and COMBO_HITS or 1
			for h = 1, hits do
				if activeBots[id] ~= bot or humanoid.Health <= 0 or targetHum.Health <= 0 then
					break
				end

				if bot.playAttack then
					bot.playAttack(bot.kind)
				end
				swingWeapon(bot.weaponMotor, bot.kind)

				if bot.kind ~= "melee" then
					fireProjectile(
						rootPart.Position + Vector3.new(0, 1.5, 0),
						targetRoot.Position + Vector3.new(0, 1, 0),
						bot.kind,
						bot.tint
					)
				else
					-- жақынтабан лунж
					local lunge = Vector3.new(toTarget.X, 0, toTarget.Z)
					if lunge.Magnitude > 0 then
						rootPart.AssemblyLinearVelocity = lunge.Unit * 16 + Vector3.new(0, 3, 0)
					end
				end

				targetHum:TakeDamage(bot.damage)
				AttackHitEvent:FireAllClients(targetHum.Parent, bot.damage)

				local dir = Vector3.new(toTarget.X, 0, toTarget.Z)
				dir = dir.Magnitude > 0 and dir.Unit or Vector3.new(0, 0, 1)
				targetRoot.AssemblyLinearVelocity = dir * KNOCKBACK_FORCE + Vector3.new(0, KNOCKBACK_UP, 0)

				if targetBot then
					targetBot.lastHitByBot = bot
					targetBot.lastHitByBotAt = os.clock()
				end

				if h < hits then
					task.wait(COMBO_GAP)
				end
			end
		end
	end)

	humanoid.Died:Connect(function()
		deathPoof(rootPart, bot.tint)

		local killer = bot.lastHitByBot
		if
			killer
			and (os.clock() - bot.lastHitByBotAt) <= KILL_CREDIT_WINDOW
			and activeBots[killer.id] == killer
			and killer.humanoid.Health > 0
		then
			handleBotKill(killer, bot)
		end

		despawnBot(bot)

		task.wait(RESPAWN_DELAY)
		if desiredBotCount >= id and not activeBots[id] then
			spawnBot(id)
		end
	end)
end

--------------------------------------------------------------------------------
-- Ашық API
--------------------------------------------------------------------------------

function BotService.GetCount(): number
	return desiredBotCount
end

function BotService.SetCount(count: number)
	count = math.clamp(math.floor(count), 0, MAX_BOTS)
	desiredBotCount = count

	for id = 1, MAX_BOTS do
		if id <= count and not activeBots[id] and not spawning[id] then
			task.spawn(spawnBot, id)
		elseif id > count and activeBots[id] then
			despawnBot(activeBots[id])
		end
	end

	BotCountChangedEvent:FireAllClients(math.min(count, 3))
	print(string.format("[Bot] Бот саны: %d", count))
end

function BotService.Init()
	RoundService.SetBotCountProvider(BotService.GetCount)
	RoundService.OnChanged(function(active)
		if active then
			resetHighlightState()
		end
	end)

	Players.PlayerAdded:Connect(function(player)
		BotCountChangedEvent:FireClient(player, math.min(desiredBotCount, 3))
	end)

	SetBotCountEvent.OnServerEvent:Connect(function(player, count)
		if AdminService.IsAdmin(player) and typeof(count) == "number" then
			BotService.SetCount(count)
		end
	end)
end

return BotService
