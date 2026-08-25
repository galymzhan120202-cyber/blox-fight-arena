local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuUI = require(script.Parent.MenuUI)
local Localization = require(script.Parent.Localization)

local SetArenaEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SetArena")
local ArenaChangedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("ArenaChanged")

local ARENAS = { "Classic", "Lava", "SkyIslands", "Frozen", "Desert", "Swamp", "NeonColosseum" }
local ARENA_LABEL_KEYS = {
	Classic = "ArenaClassic",
	Lava = "ArenaLava",
	SkyIslands = "ArenaSkyIslands",
	Frozen = "ArenaFrozen",
	Desert = "ArenaDesert",
	Swamp = "ArenaSwamp",
	NeonColosseum = "ArenaNeonColosseum",
}

local ArenaUI = {}

function ArenaUI.Init()
	local holder, titleLabel = MenuUI.AddSection(Localization.Get("ArenaSectionTitle"))
	local grid = MenuUI.CreateGridHolder(holder, 34)
	local buttons = {}

	local function refreshHighlight(arenaName: string)
		for name, button in buttons do
			MenuUI.SetSelected(button, name == arenaName)
		end
	end

	for _, arenaName in ARENAS do
		local button = MenuUI.CreateGridButton(grid, Localization.Get(ARENA_LABEL_KEYS[arenaName]))
		buttons[arenaName] = button

		button.MouseButton1Click:Connect(function()
			SetArenaEvent:FireServer(arenaName)
		end)
	end

	ArenaChangedEvent.OnClientEvent:Connect(refreshHighlight)
	refreshHighlight("Classic")

	Localization.OnChanged(function()
		titleLabel.Text = string.upper(Localization.Get("ArenaSectionTitle"))
		for arenaName, button in buttons do
			button.Text = Localization.Get(ARENA_LABEL_KEYS[arenaName])
		end
	end)
end

return ArenaUI
