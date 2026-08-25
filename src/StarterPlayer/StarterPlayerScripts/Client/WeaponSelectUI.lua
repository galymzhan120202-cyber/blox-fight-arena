local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuUI = require(script.Parent.MenuUI)
local Theme = require(script.Parent.UITheme)
local Localization = require(script.Parent.Localization)
local LoadoutLock = require(script.Parent.LoadoutLock)
local WeaponDatabase = require(ReplicatedStorage.Modules.Data.WeaponDatabase)

local SelectWeaponEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SelectWeapon")
local WeaponChangedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("WeaponChanged")

local WEAPON_ORDER = { "Sword", "Bow", "Staff", "Daggers", "Hammer", "Spear" }

local WeaponSelectUI = {}

-- Атауы мен статистикасын екі бөлек жолға бөлетін карточка (жалғыз TextButton-ға
-- сыймай, панельден асып кесіліп қалатын ескі бір жолды форматтың орнына).
local function createWeaponCard(parent: Frame, layoutOrder: number): (TextButton, TextLabel, TextLabel)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 0)
	button.AutomaticSize = Enum.AutomaticSize.Y
	button.BackgroundColor3 = Theme.Idle
	button.AutoButtonColor = false
	button.Text = ""
	button.LayoutOrder = layoutOrder
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = Theme.CornerRadius
	corner.Parent = button

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = button

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = button

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 18)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Theme.TitleFont
	nameLabel.TextSize = 15
	nameLabel.TextColor3 = Theme.Text
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.LayoutOrder = 0
	nameLabel.Parent = button

	local statsLabel = Instance.new("TextLabel")
	statsLabel.Size = UDim2.new(1, 0, 0, 14)
	statsLabel.BackgroundTransparency = 1
	statsLabel.Font = Theme.BodyFont
	statsLabel.TextSize = 11
	statsLabel.TextColor3 = Theme.MutedText
	statsLabel.TextXAlignment = Enum.TextXAlignment.Left
	statsLabel.LayoutOrder = 1
	statsLabel.Parent = button

	return button, nameLabel, statsLabel
end

function WeaponSelectUI.Init()
	local holder, titleLabel = MenuUI.AddSection(Localization.Get("WeaponSelectTitle"))
	local buttons = {}
	local cards = {}
	local extraLabels = {}

	local function setSelected(weaponName: string, selected: boolean)
		local card = cards[weaponName]
		buttons[weaponName].BackgroundColor3 = selected and Theme.Accent or Theme.Idle
		card.name.TextColor3 = selected and Theme.AccentText or Theme.Text
		card.stats.TextColor3 = selected and Theme.AccentText or Theme.MutedText
	end

	local function refreshHighlight(selected: string)
		for name in buttons do
			setSelected(name, name == selected)
		end
	end

	local function applyCardText(weaponName: string)
		local weapon = WeaponDatabase[weaponName]
		local dps = weapon.Damage / weapon.Cooldown
		cards[weaponName].name.Text = weapon.Name
		cards[weaponName].stats.Text = Localization.Get("WeaponStatFormat", weapon.Damage, weapon.Range, dps)
	end

	for index, weaponName in WEAPON_ORDER do
		local button, nameLabel, statsLabel = createWeaponCard(holder, index)
		buttons[weaponName] = button
		cards[weaponName] = { name = nameLabel, stats = statsLabel }
		table.insert(extraLabels, nameLabel)
		table.insert(extraLabels, statsLabel)
		applyCardText(weaponName)

		button.MouseButton1Click:Connect(function()
			SelectWeaponEvent:FireServer(weaponName)
		end)
	end

	WeaponChangedEvent.OnClientEvent:Connect(function(weaponName: string)
		refreshHighlight(weaponName)
	end)

	refreshHighlight("Sword")
	LoadoutLock.Attach(holder, buttons, extraLabels)

	Localization.OnChanged(function()
		titleLabel.Text = string.upper(Localization.Get("WeaponSelectTitle"))
		for _, weaponName in WEAPON_ORDER do
			applyCardText(weaponName)
		end
	end)
end

return WeaponSelectUI
