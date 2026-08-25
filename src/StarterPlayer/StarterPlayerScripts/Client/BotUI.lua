local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuUI = require(script.Parent.MenuUI)
local Localization = require(script.Parent.Localization)

local SetBotCountEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SetBotCount")
local BotCountChangedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("BotCountChanged")

local COUNTS = { 0, 1, 2, 3 }
local COUNT_LABEL_KEYS = {
	[0] = "BotNone",
	[1] = "Bot1",
	[2] = "Bot2",
	[3] = "Bot3",
}

local BotUI = {}

function BotUI.Init()
	local holder, titleLabel = MenuUI.AddSection(Localization.Get("BotSectionTitle"))
	local grid = MenuUI.CreateGridHolder(holder, 30)
	local buttons = {}

	local function refreshHighlight(count: number)
		for value, button in buttons do
			MenuUI.SetSelected(button, value == count)
		end
	end

	for _, count in COUNTS do
		local button = MenuUI.CreateGridButton(grid, Localization.Get(COUNT_LABEL_KEYS[count]))
		buttons[count] = button

		button.MouseButton1Click:Connect(function()
			SetBotCountEvent:FireServer(count)
		end)
	end

	BotCountChangedEvent.OnClientEvent:Connect(refreshHighlight)
	refreshHighlight(0)

	Localization.OnChanged(function()
		titleLabel.Text = string.upper(Localization.Get("BotSectionTitle"))
		for count, button in buttons do
			button.Text = Localization.Get(COUNT_LABEL_KEYS[count])
		end
	end)
end

return BotUI
