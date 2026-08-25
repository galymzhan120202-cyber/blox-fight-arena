local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuUI = require(script.Parent.MenuUI)

local SetGameModeEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SetGameMode")
local GameModeChangedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("GameModeChanged")

local MODES = { "Random", "Classic" }
local MODE_LABELS = {
	Random = "Random (авто ауысады)",
	Classic = "Classic (тұрақты)",
}

local GameModeUI = {}

function GameModeUI.Init()
	local holder = MenuUI.AddSection("Қару режимі")
	local buttons = {}

	local function refreshHighlight(mode: string)
		for name, button in buttons do
			MenuUI.SetSelected(button, name == mode)
		end
	end

	for _, mode in MODES do
		local button = MenuUI.CreateButton(holder, MODE_LABELS[mode])
		buttons[mode] = button

		button.MouseButton1Click:Connect(function()
			SetGameModeEvent:FireServer(mode)
		end)
	end

	GameModeChangedEvent.OnClientEvent:Connect(refreshHighlight)
	refreshHighlight("Random")
end

return GameModeUI
