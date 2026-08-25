local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.UITheme)

local WeaponChangedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("WeaponChanged")

local BottomHUD = {}

local player = Players.LocalPlayer

function BottomHUD.Init()
	local playerGui = player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BottomHUDGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local container = Instance.new("Frame")
	container.Name = "BottomHUD"
	container.Size = UDim2.fromOffset(260, 62)
	container.AnchorPoint = Vector2.new(0.5, 1)
	container.Position = UDim2.new(0.5, 0, 1, -24)
	container.BackgroundTransparency = 1
	container.Parent = screenGui

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = container

	local weaponLabel = Instance.new("TextLabel")
	weaponLabel.Size = UDim2.new(1, 0, 0, 20)
	weaponLabel.BackgroundTransparency = 1
	weaponLabel.Font = Theme.TitleFont
	weaponLabel.TextSize = 15
	weaponLabel.TextColor3 = Theme.Warning
	weaponLabel.Text = "Қару: —"
	weaponLabel.LayoutOrder = 0
	weaponLabel.Parent = container

	local barTrack = Instance.new("Frame")
	barTrack.Name = "HealthBar"
	barTrack.Size = UDim2.fromOffset(260, 26)
	barTrack.BackgroundColor3 = Theme.Background
	barTrack.BackgroundTransparency = 0.1
	barTrack.LayoutOrder = 1
	barTrack.Parent = container

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = Theme.CornerRadius
	trackCorner.Parent = barTrack

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Theme.Danger
	fill.Parent = barTrack

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = Theme.CornerRadius
	fillCorner.Parent = fill

	local hpLabel = Instance.new("TextLabel")
	hpLabel.Size = UDim2.fromScale(1, 1)
	hpLabel.BackgroundTransparency = 1
	hpLabel.Font = Theme.BodyFont
	hpLabel.TextSize = 14
	hpLabel.TextColor3 = Theme.Text
	hpLabel.Text = ""
	hpLabel.ZIndex = 2
	hpLabel.Parent = barTrack

	WeaponChangedEvent.OnClientEvent:Connect(function(weaponName: string)
		weaponLabel.Text = "Қару: " .. weaponName
	end)

	local function bindHumanoid(humanoid: Humanoid)
		local function update()
			local ratio = humanoid.Health / humanoid.MaxHealth
			fill.Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1)
			hpLabel.Text = string.format("%d / %d", math.max(0, math.floor(humanoid.Health)), humanoid.MaxHealth)
		end

		update()
		humanoid.HealthChanged:Connect(update)
	end

	local function onCharacterAdded(character: Model)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		bindHumanoid(humanoid)
	end

	if player.Character then
		onCharacterAdded(player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)
end

return BottomHUD
