local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuUI = require(script.Parent.MenuUI)
local Localization = require(script.Parent.Localization)

local SelectClassEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SelectClass")

local CLASS_NAMES = { "Warrior", "Archer", "Mage", "Assassin" }

local ClassSelectUI = {}

function ClassSelectUI.Init()
	local holder, titleLabel = MenuUI.AddSection(Localization.Get("ClassSectionTitle"))
	local buttons = {}

	local function refreshHighlight(selected: string)
		for name, button in buttons do
			MenuUI.SetSelected(button, name == selected)
		end
	end

	for _, className in CLASS_NAMES do
		local button = MenuUI.CreateButton(holder, className)
		buttons[className] = button

		button.MouseButton1Click:Connect(function()
			SelectClassEvent:FireServer(className)
			refreshHighlight(className)
		end)
	end

	refreshHighlight("Warrior")

	Localization.OnChanged(function()
		titleLabel.Text = string.upper(Localization.Get("ClassSectionTitle"))
	end)
end

return ClassSelectUI
