local TweenService = game:GetService("TweenService")

local VISUAL_MODEL_NAME = "WeaponVisual"
local SWING_OUT_TIME = 0.1
local SWING_BACK_TIME = 0.15

local WeaponModelService = {}

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

local function buildSword(): Model
	local model = Instance.new("Model")
	model.Name = VISUAL_MODEL_NAME

	local grip = newPart("Grip", Vector3.new(0.25, 0.9, 0.25), Enum.Material.Wood, BrickColor.new("Reddish brown"))
	grip.Parent = model
	model.PrimaryPart = grip

	local guard = newPart("Guard", Vector3.new(0.9, 0.15, 0.2), Enum.Material.Metal, BrickColor.new("Dark stone grey"))
	guard.CFrame = grip.CFrame * CFrame.new(0, grip.Size.Y / 2 + guard.Size.Y / 2, 0)
	guard.Parent = model
	weldTo(grip, guard)

	local blade = newPart("Blade", Vector3.new(0.16, 2, 0.55), Enum.Material.Metal, BrickColor.new("Institutional white"))
	blade.CFrame = guard.CFrame * CFrame.new(0, guard.Size.Y / 2 + blade.Size.Y / 2, 0)
	blade.Parent = model
	weldTo(grip, blade)

	local tip = newWedge("Tip", Vector3.new(0.55, 0.5, 0.16), Enum.Material.Metal, BrickColor.new("Institutional white"))
	tip.CFrame = blade.CFrame * CFrame.new(0, blade.Size.Y / 2 + tip.Size.Y / 2, 0) * CFrame.Angles(0, 0, math.rad(-90))
	tip.Parent = model
	weldTo(grip, tip)

	return model
end

local function buildBow(): Model
	local model = Instance.new("Model")
	model.Name = VISUAL_MODEL_NAME

	local grip = newPart("Grip", Vector3.new(0.2, 0.8, 0.22), Enum.Material.Wood, BrickColor.new("Reddish brown"))
	grip.Parent = model
	model.PrimaryPart = grip

	local upperLimb = newPart("UpperLimb", Vector3.new(0.12, 1.5, 0.12), Enum.Material.Wood, BrickColor.new("Reddish brown"))
	upperLimb.CFrame = grip.CFrame * CFrame.new(0, grip.Size.Y / 2 + 0.65, 0) * CFrame.Angles(0, 0, math.rad(18))
	upperLimb.Parent = model
	weldTo(grip, upperLimb)

	local lowerLimb = newPart("LowerLimb", Vector3.new(0.12, 1.5, 0.12), Enum.Material.Wood, BrickColor.new("Reddish brown"))
	lowerLimb.CFrame = grip.CFrame * CFrame.new(0, -(grip.Size.Y / 2 + 0.65), 0) * CFrame.Angles(0, 0, math.rad(-18))
	lowerLimb.Parent = model
	weldTo(grip, lowerLimb)

	local bowString = newPart("String", Vector3.new(0.05, 3.7, 0.05), Enum.Material.Metal, BrickColor.new("Institutional white"))
	bowString.CFrame = grip.CFrame * CFrame.new(0, 0, -0.4)
	bowString.Parent = model
	weldTo(grip, bowString)

	return model
end

local function buildStaff(): Model
	local model = Instance.new("Model")
	model.Name = VISUAL_MODEL_NAME

	local grip = newPart("Grip", Vector3.new(0.22, 3.4, 0.22), Enum.Material.Wood, BrickColor.new("Dark stone grey"))
	grip.Parent = model
	model.PrimaryPart = grip

	local wrap = newPart("Wrap", Vector3.new(0.32, 0.3, 0.32), Enum.Material.Fabric, BrickColor.new("Maroon"))
	wrap.CFrame = grip.CFrame * CFrame.new(0, -0.5, 0)
	wrap.Parent = model
	weldTo(grip, wrap)

	local orb = newPart(
		"Orb",
		Vector3.new(0.65, 0.65, 0.65),
		Enum.Material.Neon,
		BrickColor.new("Cyan"),
		Enum.PartType.Ball
	)
	orb.CFrame = grip.CFrame * CFrame.new(0, grip.Size.Y / 2 + 0.35, 0)
	orb.Parent = model
	weldTo(grip, orb)

	return model
end

local function buildDaggers(): Model
	local model = Instance.new("Model")
	model.Name = VISUAL_MODEL_NAME

	local grip = newPart("Grip", Vector3.new(0.18, 0.6, 0.18), Enum.Material.Wood, BrickColor.new("Really black"))
	grip.Parent = model
	model.PrimaryPart = grip

	for _, angle in { -14, 14 } do
		local blade = newPart("Blade", Vector3.new(0.12, 1.3, 0.35), Enum.Material.Metal, BrickColor.new("Institutional white"))
		blade.CFrame = grip.CFrame * CFrame.new(0, grip.Size.Y / 2 + blade.Size.Y / 2, 0) * CFrame.Angles(0, 0, math.rad(angle))
		blade.Parent = model
		weldTo(grip, blade)
	end

	return model
end

local function buildHammer(): Model
	local model = Instance.new("Model")
	model.Name = VISUAL_MODEL_NAME

	local grip = newPart("Grip", Vector3.new(0.2, 2.2, 0.2), Enum.Material.Wood, BrickColor.new("Reddish brown"))
	grip.Parent = model
	model.PrimaryPart = grip

	local head = newPart("Head", Vector3.new(1.3, 0.7, 0.7), Enum.Material.Metal, BrickColor.new("Dark stone grey"))
	head.CFrame = grip.CFrame * CFrame.new(0, grip.Size.Y / 2 + head.Size.Y / 2, 0)
	head.Parent = model
	weldTo(grip, head)

	return model
end

local function buildSpear(): Model
	local model = Instance.new("Model")
	model.Name = VISUAL_MODEL_NAME

	local grip = newPart("Grip", Vector3.new(0.15, 4.2, 0.15), Enum.Material.Wood, BrickColor.new("Reddish brown"))
	grip.Parent = model
	model.PrimaryPart = grip

	local tip = newWedge("Tip", Vector3.new(0.3, 0.7, 0.3), Enum.Material.Metal, BrickColor.new("Light stone grey"))
	tip.CFrame = grip.CFrame * CFrame.new(0, grip.Size.Y / 2 + tip.Size.Y / 2, 0)
	tip.Parent = model
	weldTo(grip, tip)

	return model
end

local WEAPON_BUILDERS = {
	Sword = buildSword,
	Bow = buildBow,
	Staff = buildStaff,
	Daggers = buildDaggers,
	Hammer = buildHammer,
	Spear = buildSpear,
}

local function removeExistingWeapon(player: Player, character: Model)
	local equipped = character:FindFirstChild(VISUAL_MODEL_NAME)
	if equipped then
		equipped:Destroy()
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	local stored = backpack and backpack:FindFirstChild(VISUAL_MODEL_NAME)
	if stored then
		stored:Destroy()
	end
end

function WeaponModelService.Equip(player: Player, character: Model, weaponName: string)
	removeExistingWeapon(player, character)

	local builder = WEAPON_BUILDERS[weaponName]
	if not builder then
		return
	end

	local model = builder()
	local grip = model.PrimaryPart :: BasePart

	local tool = Instance.new("Tool")
	tool.Name = VISUAL_MODEL_NAME
	tool.RequiresHandle = true
	tool.CanBeDropped = false

	grip.Name = "Handle"
	grip.Parent = tool

	for _, child in model:GetChildren() do
		if child ~= grip then
			child.Parent = tool
		end
	end

	model:Destroy()

	tool.Grip = CFrame.new(0, -(grip.Size.Y / 2) + 0.2, 0) * CFrame.Angles(math.rad(90), 0, 0)
	tool.Parent = player:FindFirstChildOfClass("Backpack")

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:EquipTool(tool)
	end
end

function WeaponModelService.PlaySwing(character: Model)
	local tool = character:FindFirstChild(VISUAL_MODEL_NAME) :: Tool?
	if not tool then
		return
	end

	local restGrip = tool.Grip
	local swungGrip = restGrip * CFrame.Angles(math.rad(-80), 0, 0)

	local swingOut =
		TweenService:Create(tool, TweenInfo.new(SWING_OUT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Grip = swungGrip,
		})

	swingOut.Completed:Connect(function()
		TweenService:Create(tool, TweenInfo.new(SWING_BACK_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Grip = restGrip,
		}):Play()
	end)

	swingOut:Play()
end

return WeaponModelService
