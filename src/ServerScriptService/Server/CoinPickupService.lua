local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local PlayerDataService = require(script.Parent.PlayerDataService)
local NotificationService = require(script.Parent.NotificationService)
local ArenaService = require(script.Parent.ArenaService)
local RoundService = require(script.Parent.RoundService)

local PICKUP_COUNT = 4
local COIN_MIN, COIN_MAX = 10, 30
local RESPAWN_DELAY = 15

local CoinPickupService = {}

local activeParts = {}

local function randomPosition(): Vector3
	local points = ArenaService.GetPickupPoints()
	local base = points[math.random(1, #points)]
	local jitter = Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
	return base + jitter
end

local spawnPickup

spawnPickup = function()
	local amount = math.random(COIN_MIN, COIN_MAX)

	local part = Instance.new("Part")
	part.Name = "CoinPickup"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(1.4, 1.4, 1.4)
	part.Position = randomPosition()
	activeParts[part] = true
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.BrickColor = BrickColor.new("New Yeller")
	part.Parent = Workspace

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 220, 80)
	light.Range = 10
	light.Brightness = 2
	light.Parent = part

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(80, 24)
	billboard.StudsOffset = Vector3.new(0, 1.6, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 220, 80)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = string.format("+%d", amount)
	label.Parent = billboard

	local claimed = false

	part.Touched:Connect(function(hit)
		if claimed or not RoundService.IsActive() then
			return
		end

		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end

		claimed = true
		activeParts[part] = nil
		PlayerDataService.AddCoins(player, amount)
		NotificationService.Toast(player, string.format("+%d Coins!", amount), Color3.fromRGB(255, 220, 80))
		part:Destroy()

		task.wait(RESPAWN_DELAY)
		spawnPickup()
	end)
end

local function relocateAll()
	for part in activeParts do
		part:Destroy()
	end
	table.clear(activeParts)

	for _ = 1, PICKUP_COUNT do
		spawnPickup()
	end
end

function CoinPickupService.Init()
	for _ = 1, PICKUP_COUNT do
		spawnPickup()
	end

	ArenaService.OnChanged(relocateAll)
end

return CoinPickupService
