local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ARENA_PART_TAG = "ArenaPart"
local KILL_Y = -50

local STONE_DARK = Color3.fromRGB(48, 50, 58)
local STONE_LIGHT = Color3.fromRGB(96, 100, 112)
local ACCENT = Color3.fromRGB(86, 180, 255)
local LAVA_GLOW = Color3.fromRGB(255, 90, 20)
local ICE_COLOR = Color3.fromRGB(200, 220, 235)
local SAND_COLOR = Color3.fromRGB(196, 164, 108)
local POISON_GLOW = Color3.fromRGB(120, 255, 90)
local NEON_MAGENTA = Color3.fromRGB(255, 60, 220)
local NEON_CYAN = Color3.fromRGB(60, 230, 255)

local BossService = require(script.Parent.BossService)
local AdminService = require(script.Parent.AdminService)

local SetArenaEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SetArena")
local ArenaChangedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("ArenaChanged")

local ArenaService = {}

local currentArena = "Classic"

local function track(part: BasePart): BasePart
	CollectionService:AddTag(part, ARENA_PART_TAG)
	return part
end

local function newAnchored(name: string, size: Vector3, cframe: CFrame, material: Enum.Material, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.Material = material
	part.Color = color
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = Workspace
	return track(part)
end

local function clearArena()
	for _, part in CollectionService:GetTagged(ARENA_PART_TAG) do
		part:Destroy()
	end
end

local function removeTemplateParts()
	for _, name in { "Baseplate", "Part" } do
		local part = Workspace:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			part:Destroy()
		end
	end
end

local function placeSpawn(position: Vector3)
	local spawn = Workspace:FindFirstChildOfClass("SpawnLocation")
	if not spawn then
		spawn = Instance.new("SpawnLocation")
		spawn.Parent = Workspace
	end

	spawn.Name = "ArenaSpawn"
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.CFrame = CFrame.new(position)
	spawn.Anchored = true
	spawn.Material = Enum.Material.Metal
	spawn.Color = STONE_LIGHT
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Neutral = true

	local decal = spawn:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end
end

local function buildKillFloor()
	local killPart = newAnchored(
		"KillFloor",
		Vector3.new(4000, 4, 4000),
		CFrame.new(0, KILL_Y, 0),
		Enum.Material.SmoothPlastic,
		STONE_DARK
	)
	killPart.CanCollide = false
	killPart.Transparency = 1

	killPart.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		if character and CollectionService:HasTag(character, "Boss") then
			return
		end

		local humanoid = character and character:FindFirstChild("Humanoid") :: Humanoid?
		if humanoid and humanoid.Health > 0 then
			humanoid.Health = 0
		end
	end)
end

local function buildRing(name: string, radius: number, segments: number, size: Vector3, height: number, color: Color3)
	for index = 1, segments do
		local angle = (index / segments) * math.pi * 2

		local segment = newAnchored(
			name,
			size,
			CFrame.new(math.cos(angle) * radius, height, math.sin(angle) * radius) * CFrame.Angles(0, -angle, 0),
			Enum.Material.Neon,
			color
		)
		segment.CanCollide = false
	end
end

local function buildBridge(fromPos: Vector3, toPos: Vector3, width: number, color: Color3)
	local direction = toPos - fromPos
	local length = direction.Magnitude
	local center = (fromPos + toPos) / 2
	local angle = math.atan2(direction.X, direction.Z)

	local bridge = newAnchored(
		"Bridge",
		Vector3.new(width, 1, length),
		CFrame.new(center) * CFrame.Angles(0, angle, 0),
		Enum.Material.Metal,
		color
	)
	return bridge
end

local function startLavaVent(position: Vector3)
	local RADIUS = 4
	local ACTIVE_TIME = 2
	local COOLDOWN_TIME = 3
	local DAMAGE_PER_TICK = 6
	local TICK = 0.5

	local vent = newAnchored(
		"LavaVent",
		Vector3.new(0.4, RADIUS * 2, RADIUS * 2),
		CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)),
		Enum.Material.Slate,
		Color3.fromRGB(60, 30, 25)
	)
	vent.Shape = Enum.PartType.Cylinder
	vent.CanCollide = false

	local light = Instance.new("PointLight")
	light.Color = LAVA_GLOW
	light.Range = 12
	light.Brightness = 0
	light.Parent = vent

	task.spawn(function()
		while vent.Parent do
			task.wait(COOLDOWN_TIME)
			if not vent.Parent then
				return
			end

			vent.Material = Enum.Material.Neon
			vent.Color = LAVA_GLOW
			light.Brightness = 4

			local activeUntil = os.clock() + ACTIVE_TIME
			while os.clock() < activeUntil do
				if not vent.Parent then
					return
				end

				for _, player in Players:GetPlayers() do
					local character = player.Character
					local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
					local humanoid = character and character:FindFirstChild("Humanoid") :: Humanoid?
					if rootPart and humanoid and humanoid.Health > 0 then
						local flat = Vector2.new(rootPart.Position.X - position.X, rootPart.Position.Z - position.Z)
						if flat.Magnitude <= RADIUS then
							humanoid:TakeDamage(DAMAGE_PER_TICK)
						end
					end
				end

				task.wait(TICK)
			end

			if not vent.Parent then
				return
			end

			vent.Material = Enum.Material.Slate
			vent.Color = Color3.fromRGB(60, 30, 25)
			light.Brightness = 0
		end
	end)
end

local function startPoisonPool(position: Vector3)
	local RADIUS = 5
	local DAMAGE_PER_TICK = 4
	local TICK = 1

	local pool = newAnchored(
		"PoisonPool",
		Vector3.new(RADIUS * 2, 0.4, RADIUS * 2),
		CFrame.new(position),
		Enum.Material.Neon,
		POISON_GLOW
	)
	pool.Shape = Enum.PartType.Cylinder
	pool.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	pool.CanCollide = false
	pool.Transparency = 0.25

	local light = Instance.new("PointLight")
	light.Color = POISON_GLOW
	light.Range = 10
	light.Brightness = 2
	light.Parent = pool

	task.spawn(function()
		while pool.Parent do
			for _, player in Players:GetPlayers() do
				local character = player.Character
				local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				local humanoid = character and character:FindFirstChild("Humanoid") :: Humanoid?
				if rootPart and humanoid and humanoid.Health > 0 then
					local flat = Vector2.new(rootPart.Position.X - position.X, rootPart.Position.Z - position.Z)
					if flat.Magnitude <= RADIUS then
						humanoid:TakeDamage(DAMAGE_PER_TICK)
					end
				end
			end

			task.wait(TICK)
		end
	end)
end

local function tuneLighting(ambient: Color3, outdoorAmbient: Color3, clockTime: number, fogEnd: number, atmosphereColor: Color3)
	Lighting.Ambient = ambient
	Lighting.OutdoorAmbient = outdoorAmbient
	Lighting.Brightness = 2.2
	Lighting.ClockTime = clockTime
	Lighting.FogEnd = fogEnd

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Density = 0.32
	atmosphere.Haze = 1.4
	atmosphere.Color = atmosphereColor
	atmosphere.Decay = Color3.fromRGB(90, 100, 130)
	atmosphere.Parent = Lighting
end

local function pickupRing(radius: number, count: number): { Vector3 }
	local points = {}
	for index = 1, count do
		local angle = (index / count) * math.pi * 2
		table.insert(points, Vector3.new(math.cos(angle) * radius, 3, math.sin(angle) * radius))
	end
	return points
end

local ARENA_PRESETS = {}

ARENA_PRESETS.Classic = {
	DisplayName = "Классикалық",
	Spawn = Vector3.new(0, 1, 24),
	PickupPoints = pickupRing(25, 6),
	Build = function()
		local platform =
			newAnchored("ArenaPlatform", Vector3.new(4, 120, 120), CFrame.new(0, -2, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Slate, STONE_DARK)
		platform.Shape = Enum.PartType.Cylinder

		buildRing("EdgeGlow", 60, 64, Vector3.new(3, 0.4, 1), 0.3, ACCENT)
		buildRing("InnerGlow", 18, 32, Vector3.new(2, 0.2, 0.6), 0.15, ACCENT)

		for index = 1, 8 do
			local angle = (index / 8) * math.pi * 2
			local x, z = math.cos(angle) * 38, math.sin(angle) * 38

			newAnchored("PillarBase", Vector3.new(6, 1, 6), CFrame.new(x, 0.5, z), Enum.Material.Slate, STONE_LIGHT)
			newAnchored("ArenaPillar", Vector3.new(4, 14, 4), CFrame.new(x, 8, z), Enum.Material.Rock, STONE_LIGHT)

			local crown = newAnchored("PillarCrown", Vector3.new(4.6, 0.6, 4.6), CFrame.new(x, 15.3, z), Enum.Material.Neon, ACCENT)
			crown.CanCollide = false

			local light = Instance.new("PointLight")
			light.Color = ACCENT
			light.Range = 26
			light.Brightness = 1.4
			light.Parent = crown
		end

		tuneLighting(Color3.fromRGB(58, 60, 72), Color3.fromRGB(88, 92, 108), 17.5, 100000, Color3.fromRGB(190, 200, 220))
	end,
}

ARENA_PRESETS.Lava = {
	DisplayName = "Лава шұңқыры",
	Spawn = Vector3.new(0, 1, 27),
	PickupPoints = pickupRing(24, 7), -- 7 нүкте (5 вентильден басқа бұрышта) күйіп қалмас үшін
	Build = function()
		local platform =
			newAnchored("ArenaPlatform", Vector3.new(4, 64, 64), CFrame.new(0, -2, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Basalt, Color3.fromRGB(35, 30, 32))
		platform.Shape = Enum.PartType.Cylinder

		buildRing("EdgeGlow", 32, 48, Vector3.new(3, 0.4, 1), 0.3, LAVA_GLOW)

		local ventPositions = {}
		for index = 1, 5 do
			local angle = (index / 5) * math.pi * 2
			table.insert(ventPositions, Vector3.new(math.cos(angle) * 17, 0.3, math.sin(angle) * 17))
		end
		for _, position in ventPositions do
			startLavaVent(position)
		end

		tuneLighting(Color3.fromRGB(70, 45, 40), Color3.fromRGB(100, 60, 50), 19, 100000, Color3.fromRGB(220, 160, 140))
	end,
}

ARENA_PRESETS.SkyIslands = {
	DisplayName = "Аспан аралдары",
	Spawn = Vector3.new(0, 1, 0),
	PickupPoints = {
		Vector3.new(0, 3, 0),
		Vector3.new(0, 3, 34),
		Vector3.new(34, 3, 0),
		Vector3.new(0, 3, -34),
		Vector3.new(-34, 3, 0),
	}, -- аралдардың нақты орталықтары — олқы кеңістікке түспес үшін
	Build = function()
		newAnchored("IslandCenter", Vector3.new(22, 3, 22), CFrame.new(0, -1.5, 0), Enum.Material.Slate, STONE_DARK)

		local offsets = {
			Vector3.new(0, 0, 34),
			Vector3.new(34, 0, 0),
			Vector3.new(0, 0, -34),
			Vector3.new(-34, 0, 0),
		}

		for index, offset in offsets do
			newAnchored("IslandOuter" .. index, Vector3.new(14, 3, 14), CFrame.new(offset.X, -1.5, offset.Z), Enum.Material.Slate, STONE_LIGHT)
			buildBridge(Vector3.new(0, 0, 0), offset, 5, STONE_LIGHT)
		end

		buildRing("InnerGlow", 11, 24, Vector3.new(1.6, 0.2, 0.5), 0.05, ACCENT)

		tuneLighting(Color3.fromRGB(50, 58, 78), Color3.fromRGB(80, 95, 120), 10, 400, Color3.fromRGB(170, 190, 220))
	end,
}

ARENA_PRESETS.Frozen = {
	DisplayName = "Мұзды құрсау",
	Spawn = Vector3.new(0, 1, 30),
	PickupPoints = pickupRing(27, 6),
	Build = function()
		local platform = newAnchored("ArenaPlatform", Vector3.new(70, 4, 70), CFrame.new(0, -2, 0), Enum.Material.Ice, ICE_COLOR)
		platform.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.02, 0.5)

		buildRing("EdgeGlow", 35, 56, Vector3.new(3, 0.4, 1), 0.3, Color3.fromRGB(150, 210, 255))

		for index = 1, 6 do
			local angle = (index / 6) * math.pi * 2
			local x, z = math.cos(angle) * 20, math.sin(angle) * 20
			newAnchored("IceStump", Vector3.new(3, 4, 3), CFrame.new(x, 2, z), Enum.Material.Glacier, ICE_COLOR)
		end

		tuneLighting(Color3.fromRGB(80, 90, 110), Color3.fromRGB(120, 140, 170), 13, 500, Color3.fromRGB(210, 225, 240))
	end,
}

ARENA_PRESETS.Desert = {
	DisplayName = "Шөл дала",
	Spawn = Vector3.new(0, 1, 26),
	PickupPoints = pickupRing(26, 6),
	Build = function()
		local platform =
			newAnchored("ArenaPlatform", Vector3.new(4, 110, 110), CFrame.new(0, -2, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Sand, SAND_COLOR)
		platform.Shape = Enum.PartType.Cylinder

		buildRing("EdgeGlow", 55, 56, Vector3.new(3, 0.4, 1), 0.3, Color3.fromRGB(255, 200, 110))

		for index = 1, 6 do
			local angle = (index / 6) * math.pi * 2
			local x, z = math.cos(angle) * 32, math.sin(angle) * 32

			local dune = newAnchored(
				"Dune",
				Vector3.new(12, 4, 12),
				CFrame.new(x, 0, z),
				Enum.Material.Sand,
				Color3.fromRGB(180, 148, 96)
			)
			dune.Shape = Enum.PartType.Ball
		end

		for index = 1, 5 do
			local angle = (index / 5) * math.pi * 2 + math.rad(36)
			local x, z = math.cos(angle) * 16, math.sin(angle) * 16

			newAnchored("CactusBody", Vector3.new(1.4, 6, 1.4), CFrame.new(x, 3, z), Enum.Material.Grass, Color3.fromRGB(70, 120, 60))
			newAnchored("CactusArm", Vector3.new(0.8, 2.4, 0.8), CFrame.new(x + 1, 4, z), Enum.Material.Grass, Color3.fromRGB(70, 120, 60))
		end

		tuneLighting(Color3.fromRGB(120, 100, 70), Color3.fromRGB(180, 150, 100), 13.5, 250, Color3.fromRGB(230, 190, 130))
	end,
}

ARENA_PRESETS.Swamp = {
	DisplayName = "Улы батпақ",
	Spawn = Vector3.new(0, 1, 28),
	PickupPoints = pickupRing(23, 7),
	Build = function()
		local platform = newAnchored(
			"ArenaPlatform",
			Vector3.new(4, 90, 90),
			CFrame.new(0, -2, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Enum.Material.Ground,
			Color3.fromRGB(55, 62, 45)
		)
		platform.Shape = Enum.PartType.Cylinder

		buildRing("EdgeGlow", 45, 52, Vector3.new(3, 0.4, 1), 0.3, POISON_GLOW)

		local poolPositions = {}
		for index = 1, 5 do
			local angle = (index / 5) * math.pi * 2
			table.insert(poolPositions, Vector3.new(math.cos(angle) * 18, 0.3, math.sin(angle) * 18))
		end
		for _, position in poolPositions do
			startPoisonPool(position)
		end

		for index = 1, 6 do
			local angle = (index / 6) * math.pi * 2 + math.rad(30)
			local x, z = math.cos(angle) * 30, math.sin(angle) * 30
			newAnchored("DeadTree", Vector3.new(1.6, 10, 1.6), CFrame.new(x, 4, z), Enum.Material.Wood, Color3.fromRGB(45, 40, 35))
		end

		tuneLighting(Color3.fromRGB(45, 55, 40), Color3.fromRGB(70, 85, 60), 21, 45, Color3.fromRGB(120, 160, 110))
	end,
}

ARENA_PRESETS.NeonColosseum = {
	DisplayName = "Неон колизей",
	Spawn = Vector3.new(0, 1, 24),
	PickupPoints = pickupRing(22, 6),
	Build = function()
		local platform =
			newAnchored("ArenaPlatform", Vector3.new(4, 100, 100), CFrame.new(0, -2, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Metal, Color3.fromRGB(18, 18, 24))
		platform.Shape = Enum.PartType.Cylinder

		buildRing("EdgeGlowOuter", 50, 60, Vector3.new(3, 0.4, 1), 0.3, NEON_CYAN)
		buildRing("EdgeGlowInner", 34, 48, Vector3.new(2, 0.2, 0.6), 0.15, NEON_MAGENTA)
		buildRing("CoreGlow", 8, 20, Vector3.new(1.4, 0.2, 0.5), 0.1, NEON_CYAN)

		for index = 1, 8 do
			local angle = (index / 8) * math.pi * 2
			local x, z = math.cos(angle) * 40, math.sin(angle) * 40
			local color = (index % 2 == 0) and NEON_CYAN or NEON_MAGENTA

			newAnchored("PillarBase", Vector3.new(5, 1, 5), CFrame.new(x, 0.5, z), Enum.Material.Metal, Color3.fromRGB(24, 24, 30))
			local pillar = newAnchored("NeonPillar", Vector3.new(1.4, 18, 1.4), CFrame.new(x, 10, z), Enum.Material.Neon, color)
			pillar.CanCollide = false

			local light = Instance.new("PointLight")
			light.Color = color
			light.Range = 22
			light.Brightness = 2
			light.Parent = pillar
		end

		tuneLighting(Color3.fromRGB(30, 20, 45), Color3.fromRGB(50, 30, 70), 0, 180, Color3.fromRGB(120, 60, 160))
	end,
}

local ARENA_ORDER = { "Classic", "Lava", "SkyIslands", "Frozen", "Desert", "Swamp", "NeonColosseum" }

local function teleportAllPlayers(spawnPosition: Vector3)
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if rootPart then
			local jitter = Vector3.new(math.random(-4, 4), 3, math.random(-4, 4))
			rootPart.CFrame = CFrame.new(spawnPosition + jitter)
		end
	end
end

local changeListeners = {}

local ROTATION_INTERVAL_SECONDS = 4 * 24 * 60 * 60 -- 4 күн
local ROTATION_CHECK_INTERVAL = 30 * 60 -- сервер ұзақ жұмыс істесе, әр 30 минутта тексереді

-- Барлық сервер данасы (жаңа Roblox сервер іске қосылғанда) бірдей нәтиже алуы үшін
-- нақты уақытқа (os.time) негізделген жаһандық индекс есептейді — сервер өзі 4 күн
-- бойы тірі қалуын күтпейді, әр жаңа сервер сол сәттегі "кезектегі" аренаны алады.
local function scheduledArena(): string
	local index = math.floor(os.time() / ROTATION_INTERVAL_SECONDS) % #ARENA_ORDER
	return ARENA_ORDER[index + 1]
end

function ArenaService.GetCurrent(): string
	return currentArena
end

function ArenaService.GetPickupPoints(): { Vector3 }
	local preset = ARENA_PRESETS[currentArena]
	return (preset and preset.PickupPoints) or { Vector3.new(0, 3, 0) }
end

-- Арена ауысқанда хабардар болғысы келетін сервистер (мыс. HP/Coin pickups)
-- осы арқылы тіркеледі — олар ArenaService-ті require етеді, ArenaService оларды
-- require етпейді, сондықтан циклдік тәуелділік болмайды.
function ArenaService.OnChanged(callback: (string) -> ())
	table.insert(changeListeners, callback)
end

function ArenaService.SetArena(name: string): boolean
	local preset = ARENA_PRESETS[name]
	if not preset then
		return false
	end

	clearArena()
	preset.Build()
	buildKillFloor()
	placeSpawn(preset.Spawn)
	teleportAllPlayers(preset.Spawn)
	BossService.TeleportTo(preset.Spawn)

	currentArena = name
	ArenaChangedEvent:FireAllClients(name)
	print(string.format("[Arena] Ауыстырылды: %s", preset.DisplayName))

	for _, callback in changeListeners do
		task.spawn(callback, name)
	end

	return true
end

function ArenaService.Init()
	Players.RespawnTime = 3

	removeTemplateParts()
	ArenaService.SetArena(scheduledArena())

	task.spawn(function()
		while true do
			task.wait(ROTATION_CHECK_INTERVAL)

			local expected = scheduledArena()
			if expected ~= currentArena then
				print(string.format("[Arena] 4 күндік автоматты ротация: %s", expected))
				ArenaService.SetArena(expected)
			end
		end
	end)

	Players.PlayerAdded:Connect(function(player)
		ArenaChangedEvent:FireClient(player, currentArena)
	end)

	SetArenaEvent.OnServerEvent:Connect(function(player, name)
		if AdminService.IsAdmin(player) and typeof(name) == "string" then
			ArenaService.SetArena(name)
		end
	end)
end

return ArenaService
