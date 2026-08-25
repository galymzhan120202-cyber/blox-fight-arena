local Players = game:GetService("Players")

local Theme = require(script.Parent.UITheme)
local Localization = require(script.Parent.Localization)

local MenuUI = {}

local player = Players.LocalPlayer
local scroller: ScrollingFrame
local tabButtons = {}
local sectionsByTab = {}
local sectionOrder = 0
local activeTab = "Ойын"

local TABS = { "Ойын", "Дүкен" }
local TAB_LABEL_KEYS = { ["Ойын"] = "TabGame", ["Дүкен"] = "TabShop" }

local function setActiveTab(tabName: string)
	activeTab = tabName

	for name, button in tabButtons do
		MenuUI.SetSelected(button, name == tabName)
	end

	for name, sections in sectionsByTab do
		for _, section in sections do
			section.Visible = (name == tabName)
		end
	end
end

function MenuUI.Init()
	local playerGui = player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MenuGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local root = Instance.new("Frame")
	root.Name = "Menu"
	root.Size = UDim2.fromOffset(210, 460)
	root.Position = UDim2.fromOffset(16, 16)
	root.BackgroundTransparency = 1
	root.Parent = screenGui

	local tabBar = Instance.new("Frame")
	tabBar.Name = "TabBar"
	tabBar.Size = UDim2.new(1, 0, 0, 32)
	tabBar.BackgroundTransparency = 1
	tabBar.Parent = root

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 6)
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Parent = tabBar

	for index, tabName in TABS do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(0.5, -3, 1, 0)
		button.BackgroundColor3 = Theme.Idle
		button.TextColor3 = Theme.Text
		button.Font = Theme.TitleFont
		button.TextSize = 13
		button.Text = Localization.Get(TAB_LABEL_KEYS[tabName])
		button.AutoButtonColor = false
		button.LayoutOrder = index
		button.Parent = tabBar

		local corner = Instance.new("UICorner")
		corner.CornerRadius = Theme.CornerRadius
		corner.Parent = button

		tabButtons[tabName] = button
		sectionsByTab[tabName] = {}

		button.MouseButton1Click:Connect(function()
			setActiveTab(tabName)
		end)
	end

	scroller = Instance.new("ScrollingFrame")
	scroller.Name = "Content"
	scroller.Position = UDim2.new(0, 0, 0, 38)
	scroller.Size = UDim2.new(1, 0, 1, -38)
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroller.ScrollBarThickness = 4
	scroller.ScrollBarImageColor3 = Theme.Accent
	scroller.Parent = root

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroller

	setActiveTab(activeTab)

	Localization.OnChanged(function()
		for tabName, button in tabButtons do
			button.Text = Localization.Get(TAB_LABEL_KEYS[tabName])
		end
	end)
end

function MenuUI.AddSection(title: string, tabName: string?): (Frame, TextLabel)
	tabName = tabName or "Ойын"
	sectionOrder += 1

	local section = Instance.new("Frame")
	section.Name = title .. "Section"
	section.AutomaticSize = Enum.AutomaticSize.Y
	section.Size = UDim2.fromScale(1, 0)
	section.BackgroundColor3 = Theme.Background
	section.BackgroundTransparency = Theme.BackgroundTransparency
	section.LayoutOrder = sectionOrder
	section.Visible = (tabName == activeTab)
	section.Parent = scroller

	table.insert(sectionsByTab[tabName], section)

	local corner = Instance.new("UICorner")
	corner.CornerRadius = Theme.CornerRadius
	corner.Parent = section

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = section

	local outerLayout = Instance.new("UIListLayout")
	outerLayout.Padding = UDim.new(0, 6)
	outerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	outerLayout.Parent = section

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0, 16)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Theme.TitleFont
	titleLabel.TextSize = 13
	titleLabel.TextColor3 = Theme.MutedText
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Text = string.upper(title)
	titleLabel.LayoutOrder = 0
	titleLabel.Parent = section

	local buttonHolder = Instance.new("Frame")
	buttonHolder.Name = "Buttons"
	buttonHolder.AutomaticSize = Enum.AutomaticSize.Y
	buttonHolder.Size = UDim2.fromScale(1, 0)
	buttonHolder.BackgroundTransparency = 1
	buttonHolder.LayoutOrder = 1
	buttonHolder.Parent = section

	local innerLayout = Instance.new("UIListLayout")
	innerLayout.Padding = UDim.new(0, 4)
	innerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	innerLayout.Parent = buttonHolder

	return buttonHolder, titleLabel
end

function MenuUI.CreateButton(parent: Frame, text: string): TextButton
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 32)
	button.BackgroundColor3 = Theme.Idle
	button.TextColor3 = Theme.Text
	button.Font = Theme.BodyFont
	button.TextSize = 15
	button.Text = text
	button.AutoButtonColor = false
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = Theme.CornerRadius
	corner.Parent = button

	return button
end

-- Free Fire-дегідей жинақы, 2-бағанды режим/таңдау торы (Round/Weapon сияқты
-- тізім емес, ArenaUI/BotUI/MatchModeUI/GameModeUI-ге арналған).
function MenuUI.CreateGridHolder(parent: Frame, cellHeight: number?): Frame
	local grid = Instance.new("Frame")
	grid.AutomaticSize = Enum.AutomaticSize.Y
	grid.Size = UDim2.fromScale(1, 0)
	grid.BackgroundTransparency = 1
	grid.Parent = parent

	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.new(0.5, -3, 0, cellHeight or 34)
	layout.CellPadding = UDim2.fromOffset(3, 3)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid

	return grid
end

function MenuUI.CreateGridButton(parent: Frame, text: string): TextButton
	local button = Instance.new("TextButton")
	button.BackgroundColor3 = Theme.Idle
	button.TextColor3 = Theme.Text
	button.Font = Theme.BodyFont
	button.TextSize = 12
	button.TextWrapped = true
	button.Text = text
	button.AutoButtonColor = false
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = Theme.CornerRadius
	corner.Parent = button

	return button
end

function MenuUI.SetSelected(button: TextButton, selected: boolean)
	button.BackgroundColor3 = selected and Theme.Accent or Theme.Idle
	button.TextColor3 = selected and Theme.AccentText or Theme.Text
end

return MenuUI
