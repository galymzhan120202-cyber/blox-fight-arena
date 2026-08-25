local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuUI = require(script.Parent.MenuUI)
local Localization = require(script.Parent.Localization)

local SetGameModeEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SetGameMode")
local GameModeChangedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("GameModeChanged")

local MODES = { "Random", "Classic" }
local MODE_LABEL_KEYS = {
	Random = "WeaponModeRandom",
	Classic = "WeaponModeClassic",
}

local GameModeUI = {}

function GameModeUI.Init()
	local holder, titleLabel = MenuUI.AddSection(Localization.Get("WeaponModeTitle"))
	local buttons = {}

	local function refreshHighlight(mode: string)
		for name, button in buttons do
			MenuUI.SetSelected(button, name == mode)
		end
	end

	for _, mode in MODES do
		local button = MenuUI.CreateButton(holder, Localization.Get(MODE_LABEL_KEYS[mode]))
		buttons[mode] = button

		button.MouseButton1Click:Connect(function()
			SetGameModeEvent:FireServer(mode)
		end)
	end

	GameModeChangedEvent.OnClientEvent:Connect(refreshHighlight)
	refreshHighlight("Random")

	Localization.OnChanged(function()
		titleLabel.Text = string.upper(Localization.Get("WeaponModeTitle"))
		for mode, button in buttons do
			button.Text = Localization.Get(MODE_LABEL_KEYS[mode])
		end
	end)
end

return GameModeUI
