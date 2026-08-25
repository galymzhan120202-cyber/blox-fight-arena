local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuUI = require(script.Parent.MenuUI)
local Localization = require(script.Parent.Localization)
local WeaponDatabase = require(ReplicatedStorage.Modules.Data.WeaponDatabase)

local SelectWeaponEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SelectWeapon")
local WeaponChangedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("WeaponChanged")

local WEAPON_ORDER = { "Sword", "Bow", "Staff", "Daggers", "Hammer", "Spear" }

local WeaponSelectUI = {}

function WeaponSelectUI.Init()
	local holder, titleLabel = MenuUI.AddSection(Localization.Get("WeaponShopTitle"), "Дүкен")
	local buttons = {}

	local function refreshHighlight(selected: string)
		for name, button in buttons do
			MenuUI.SetSelected(button, name == selected)
		end
	end

	local function applyButtonText(weaponName: string)
		local weapon = WeaponDatabase[weaponName]
		local dps = weapon.Damage / weapon.Cooldown
		buttons[weaponName].Text = Localization.Get("WeaponStatFormat", weapon.Name, weapon.Damage, weapon.Range, dps)
	end

	for _, weaponName in WEAPON_ORDER do
		local button = MenuUI.CreateButton(holder, "")
		buttons[weaponName] = button
		applyButtonText(weaponName)

		button.MouseButton1Click:Connect(function()
			SelectWeaponEvent:FireServer(weaponName)
		end)
	end

	WeaponChangedEvent.OnClientEvent:Connect(function(weaponName: string)
		refreshHighlight(weaponName)
	end)

	refreshHighlight("Sword")

	Localization.OnChanged(function()
		titleLabel.Text = string.upper(Localization.Get("WeaponShopTitle"))
		for _, weaponName in WEAPON_ORDER do
			applyButtonText(weaponName)
		end
	end)
end

return WeaponSelectUI
