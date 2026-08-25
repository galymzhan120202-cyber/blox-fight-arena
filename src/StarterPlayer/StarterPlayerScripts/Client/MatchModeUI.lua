local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuUI = require(script.Parent.MenuUI)

local SetMatchModeEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SetMatchMode")
local MatchModeChangedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("MatchModeChanged")

local MODES = { "FFA", "Team", "Boss", "Training" }
local MODE_LABELS = {
	FFA = "FFA (еркін ұрыс)",
	Team = "Team (2ге2 / 2ге1)",
	Boss = "Boss (тек боссқа қарсы)",
	Training = "Жаттығу (Dummy, PvP жоқ)",
}

local MatchModeUI = {}

function MatchModeUI.Init()
	local holder = MenuUI.AddSection("Ойын режимі")
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
			SetMatchModeEvent:FireServer(mode)
		end)
	end

	MatchModeChangedEvent.OnClientEvent:Connect(refreshHighlight)
	refreshHighlight("FFA")
end

return MatchModeUI
