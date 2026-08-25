local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local NotificationService = require(script.Parent.NotificationService)

local PICKUP_COUNT = 3
local SPAWN_RADIUS = 45
local HEAL_AMOUNT = 35
local RESPAWN_DELAY = 20

local HealthPickupService = {}

local function randomPosition(): Vector3
	local angle = math.random() * math.pi * 2
	local radius = math.random() * SPAWN_RADIUS
	return Vector3.new(math.cos(angle) * radius, 3, math.sin(angle) * radius)
end

local spawnPickup

spawnPickup = function()
	local part = Instance.new("Part")
	part.Name = "HealthPickup"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(1.6, 1.6, 1.6)
	part.Position = randomPosition()
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.BrickColor = BrickColor.new("Lime green")
	part.Parent = Workspace

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(90, 255, 120)
	light.Range = 10
	light.Brightness = 2
	light.Parent = part

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(90, 24)
	billboard.StudsOffset = Vector3.new(0, 1.8, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(90, 255, 120)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = string.format("+%d HP", HEAL_AMOUNT)
	label.Parent = billboard

	local claimed = false

	part.Touched:Connect(function(hit)
		if claimed then
			return
		end

		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		local humanoid = character and character:FindFirstChild("Humanoid") :: Humanoid?
		if not player or not humanoid or humanoid.Health <= 0 then
			return
		end

		if humanoid.Health >= humanoid.MaxHealth then
			return
		end

		claimed = true
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + HEAL_AMOUNT)
		NotificationService.Toast(player, string.format("+%d HP!", HEAL_AMOUNT), Color3.fromRGB(90, 255, 120))
		part:Destroy()

		task.wait(RESPAWN_DELAY)
		spawnPickup()
	end)
end

function HealthPickupService.Init()
	for _ = 1, PICKUP_COUNT do
		spawnPickup()
	end
end

return HealthPickupService
