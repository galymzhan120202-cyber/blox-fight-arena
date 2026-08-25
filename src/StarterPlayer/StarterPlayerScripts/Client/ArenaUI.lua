local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuUI = require(script.Parent.MenuUI)

local SetArenaEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SetArena")
local ArenaChangedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("ArenaChanged")

local ARENAS = { "Classic", "Lava", "SkyIslands", "Frozen" }
local ARENA_LABELS = {
	Classic = "Классикалық",
	Lava = "Лава шұңқыры",
	SkyIslands = "Аспан аралдары",
	Frozen = "Мұзды құрсау",
}

local ArenaUI = {}

function ArenaUI.Init()
	local holder = MenuUI.AddSection("Арена")
	local buttons = {}

	local function refreshHighlight(arenaName: string)
		for name, button in buttons do
			MenuUI.SetSelected(button, name == arenaName)
		end
	end

	for _, arenaName in ARENAS do
		local button = MenuUI.CreateButton(holder, ARENA_LABELS[arenaName])
		buttons[arenaName] = button

		button.MouseButton1Click:Connect(function()
			SetArenaEvent:FireServer(arenaName)
		end)
	end

	ArenaChangedEvent.OnClientEvent:Connect(refreshHighlight)
	refreshHighlight("Classic")
end

return ArenaUI
