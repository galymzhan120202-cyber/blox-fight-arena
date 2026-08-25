local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local NameplateService = require(script.Parent.NameplateService)

local DAMAGEABLE_TAG = "Damageable"
local RESPAWN_DELAY = 3
local DUMMY_HEALTH = 100
local ACCENT = Color3.fromRGB(255, 170, 70)

local DummyService = {}

local activeDummy: Model? = nil
local desiredActive = false

local createDummy

createDummy = function()
	local model = Instance.new("Model")
	model.Name = "TrainingDummy"

	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(2.4, 4, 1.4)
	rootPart.Position = Vector3.new(10, 2, 0)
	rootPart.Anchored = true
	rootPart.Material = Enum.Material.WoodPlanks
	rootPart.Color = Color3.fromRGB(170, 120, 70)
	rootPart.TopSurface = Enum.SurfaceType.Smooth
	rootPart.BottomSurface = Enum.SurfaceType.Smooth
	rootPart.Parent = model

	local head = Instance.new("Part")
	head.Name = "DummyHead"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.5, 1.5, 1.5)
	head.CFrame = rootPart.CFrame * CFrame.new(0, rootPart.Size.Y / 2 + 0.75, 0)
	head.Anchored = true
	head.CanCollide = false
	head.Material = Enum.Material.Fabric
	head.Color = Color3.fromRGB(200, 160, 110)
	head.Parent = model

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = DUMMY_HEALTH
	humanoid.Health = DUMMY_HEALTH
	humanoid.Parent = model

	model.PrimaryPart = rootPart
	model.Parent = Workspace

	CollectionService:AddTag(model, DAMAGEABLE_TAG)

	NameplateService.Attach(rootPart, humanoid, "Training Dummy", ACCENT, 3.4)

	activeDummy = model

	humanoid.Died:Connect(function()
		task.wait(RESPAWN_DELAY)

		if model.Parent then
			model:Destroy()
		end

		if activeDummy == model then
			activeDummy = nil
		end

		if desiredActive then
			createDummy()
		end
	end)
end

function DummyService.SetActive(active: boolean)
	desiredActive = active

	if active then
		if not activeDummy then
			createDummy()
		end
	else
		if activeDummy then
			activeDummy:Destroy()
			activeDummy = nil
		end
	end
end

function DummyService.Init()
	-- Dummy тек MatchModeService "Training" режимін таңдағанда пайда болады.
end

return DummyService
