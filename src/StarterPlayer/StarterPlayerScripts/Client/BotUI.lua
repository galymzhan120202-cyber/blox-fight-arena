local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuUI = require(script.Parent.MenuUI)

local SetBotCountEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SetBotCount")
local BotCountChangedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("BotCountChanged")

local COUNTS = { 0, 1, 2, 3 }
local COUNT_LABELS = {
	[0] = "Боттарсыз",
	[1] = "1 бот",
	[2] = "2 бот",
	[3] = "3 бот",
}

local BotUI = {}

function BotUI.Init()
	local holder = MenuUI.AddSection("Боттар")
	local buttons = {}

	local function refreshHighlight(count: number)
		for value, button in buttons do
			MenuUI.SetSelected(button, value == count)
		end
	end

	for _, count in COUNTS do
		local button = MenuUI.CreateButton(holder, COUNT_LABELS[count])
		buttons[count] = button

		button.MouseButton1Click:Connect(function()
			SetBotCountEvent:FireServer(count)
		end)
	end

	BotCountChangedEvent.OnClientEvent:Connect(refreshHighlight)
	refreshHighlight(0)
end

return BotUI
