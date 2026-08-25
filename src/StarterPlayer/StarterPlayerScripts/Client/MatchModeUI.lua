local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuUI = require(script.Parent.MenuUI)
local Localization = require(script.Parent.Localization)

local SetMatchModeEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SetMatchMode")
local MatchModeChangedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("MatchModeChanged")

local MODES = { "FFA", "Team", "Boss", "Training" }
local MODE_LABEL_KEYS = {
	FFA = "MatchModeFFA",
	Team = "MatchModeTeam",
	Boss = "MatchModeBoss",
	Training = "MatchModeTraining",
}

local MatchModeUI = {}

function MatchModeUI.Init()
	local holder, titleLabel = MenuUI.AddSection(Localization.Get("MatchModeTitle"))
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
			SetMatchModeEvent:FireServer(mode)
		end)
	end

	MatchModeChangedEvent.OnClientEvent:Connect(refreshHighlight)
	refreshHighlight("FFA")

	Localization.OnChanged(function()
		titleLabel.Text = string.upper(Localization.Get("MatchModeTitle"))
		for mode, button in buttons do
			button.Text = Localization.Get(MODE_LABEL_KEYS[mode])
		end
	end)
end

return MatchModeUI
