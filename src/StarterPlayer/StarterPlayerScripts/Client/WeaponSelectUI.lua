local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuUI = require(script.Parent.MenuUI)
local WeaponDatabase = require(ReplicatedStorage.Modules.Data.WeaponDatabase)

local SelectWeaponEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SelectWeapon")
local WeaponChangedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("WeaponChanged")

local WEAPON_ORDER = { "Sword", "Bow", "Staff", "Daggers", "Hammer", "Spear" }

local WeaponSelectUI = {}

function WeaponSelectUI.Init()
	local holder = MenuUI.AddSection("Қару дүкені", "Дүкен")
	local buttons = {}

	local function refreshHighlight(selected: string)
		for name, button in buttons do
			MenuUI.SetSelected(button, name == selected)
		end
	end

	for _, weaponName in WEAPON_ORDER do
		local weapon = WeaponDatabase[weaponName]
		local dps = weapon.Damage / weapon.Cooldown

		local button = MenuUI.CreateButton(
			holder,
			string.format("%s (DMG %d, Range %d, DPS %.1f)", weapon.Name, weapon.Damage, weapon.Range, dps)
		)
		buttons[weaponName] = button

		button.MouseButton1Click:Connect(function()
			SelectWeaponEvent:FireServer(weaponName)
		end)
	end

	WeaponChangedEvent.OnClientEvent:Connect(function(weaponName: string)
		refreshHighlight(weaponName)
	end)

	refreshHighlight("Sword")
end

return WeaponSelectUI
