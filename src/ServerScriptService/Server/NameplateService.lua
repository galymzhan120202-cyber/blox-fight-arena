local NameplateService = {}

function NameplateService.Attach(
	adornee: BasePart,
	humanoid: Humanoid,
	displayName: string,
	accentColor: Color3,
	studsOffset: number
)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Nameplate"
	billboard.Size = UDim2.fromOffset(190, 40)
	billboard.StudsOffset = Vector3.new(0, studsOffset, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 220
	billboard.Parent = adornee

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 3)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = billboard

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 17)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.TextColor3 = accentColor
	nameLabel.TextStrokeTransparency = 0.55
	nameLabel.Text = displayName
	nameLabel.LayoutOrder = 0
	nameLabel.Parent = billboard

	local barTrack = Instance.new("Frame")
	barTrack.Name = "HealthBar"
	barTrack.Size = UDim2.fromOffset(150, 12)
	barTrack.BackgroundColor3 = Color3.fromRGB(20, 21, 26)
	barTrack.BackgroundTransparency = 0.15
	barTrack.LayoutOrder = 1
	barTrack.Parent = billboard

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, 4)
	trackCorner.Parent = barTrack

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = accentColor
	fill.Parent = barTrack

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = fill

	local hpLabel = Instance.new("TextLabel")
	hpLabel.Size = UDim2.fromScale(1, 1)
	hpLabel.BackgroundTransparency = 1
	hpLabel.Font = Enum.Font.GothamMedium
	hpLabel.TextSize = 10
	hpLabel.TextColor3 = Color3.fromRGB(240, 241, 245)
	hpLabel.ZIndex = 2
	hpLabel.Parent = barTrack

	local function update()
		local ratio = humanoid.Health / humanoid.MaxHealth
		fill.Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1)
		hpLabel.Text = string.format("%d / %d", math.max(0, math.floor(humanoid.Health)), humanoid.MaxHealth)
	end

	update()
	humanoid.HealthChanged:Connect(update)
end

return NameplateService
