local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuUI = require(script.Parent.MenuUI)
local Theme = require(script.Parent.UITheme)
local Localization = require(script.Parent.Localization)
local WeaponSkinsDatabase = require(ReplicatedStorage.Modules.Data.WeaponSkinsDatabase)

local PurchaseWeaponSkinEvent = ReplicatedStorage.RemoteEvents:WaitForChild("PurchaseWeaponSkin")
local EquipWeaponSkinEvent = ReplicatedStorage.RemoteEvents:WaitForChild("EquipWeaponSkin")
local WeaponSkinsUpdatedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("WeaponSkinsUpdated")

local WEAPON_ORDER = { "Sword", "Bow", "Staff", "Daggers", "Hammer", "Spear" }

local WeaponSkinsUI = {}

function WeaponSkinsUI.Init()
	local holder, titleLabel = MenuUI.AddSection(Localization.Get("WeaponSkinsSectionTitle"), "Дүкен")

	-- 1-деңгей: қай қаруға скин таңдайтынымызды белгілейтін шағын батырма қатары.
	local weaponPickerHolder = Instance.new("Frame")
	weaponPickerHolder.AutomaticSize = Enum.AutomaticSize.Y
	weaponPickerHolder.Size = UDim2.fromScale(1, 0)
	weaponPickerHolder.BackgroundTransparency = 1
	weaponPickerHolder.Parent = holder

	local weaponPickerLayout = Instance.new("UIGridLayout")
	weaponPickerLayout.CellSize = UDim2.new(0.5, -3, 0, 26)
	weaponPickerLayout.CellPadding = UDim2.fromOffset(3, 3)
	weaponPickerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	weaponPickerLayout.Parent = weaponPickerHolder

	local weaponButtons = {}
	local selectedWeapon = "Sword"

	local coinsLabel = MenuUI.CreateButton(holder, "")
	coinsLabel.Active = false
	coinsLabel.AutoButtonColor = false

	local skinButtons = {}
	local state = { Coins = 0, Owned = {}, Equipped = {} }

	local function refreshWeaponHighlight()
		for weaponName, button in weaponButtons do
			MenuUI.SetSelected(button, weaponName == selectedWeapon)
		end
	end

	local function refreshSkins()
		coinsLabel.Text = Localization.Get("CoinsLabel", state.Coins)

		local equippedSkinId = state.Equipped[selectedWeapon] or "Default"

		for _, skin in WeaponSkinsDatabase do
			local button = skinButtons[skin.Id]
			local ownedKey = selectedWeapon .. "_" .. skin.Id
			local owned = skin.Id == "Default" or state.Owned[ownedKey]
			local equipped = equippedSkinId == skin.Id

			if equipped then
				button.Text = Localization.Get("SkinEquipped", skin.Name)
				MenuUI.SetSelected(button, true)
			elseif owned then
				button.Text = Localization.Get("SkinWear", skin.Name)
				MenuUI.SetSelected(button, false)
			else
				button.Text = Localization.Get("SkinBuy", skin.Name, skin.Price)
				MenuUI.SetSelected(button, false)
			end
		end
	end

	for index, weaponName in WEAPON_ORDER do
		local button = Instance.new("TextButton")
		button.LayoutOrder = index
		button.BackgroundColor3 = Theme.Idle
		button.TextColor3 = Theme.Text
		button.Font = Theme.BodyFont
		button.TextSize = 13
		button.Text = weaponName
		button.AutoButtonColor = false
		button.Parent = weaponPickerHolder

		local corner = Instance.new("UICorner")
		corner.CornerRadius = Theme.CornerRadius
		corner.Parent = button

		weaponButtons[weaponName] = button

		button.MouseButton1Click:Connect(function()
			selectedWeapon = weaponName
			refreshWeaponHighlight()
			refreshSkins()
		end)
	end

	for _, skin in WeaponSkinsDatabase do
		local button = MenuUI.CreateButton(holder, skin.Name)
		skinButtons[skin.Id] = button

		button.MouseButton1Click:Connect(function()
			local ownedKey = selectedWeapon .. "_" .. skin.Id
			if skin.Id == "Default" or state.Owned[ownedKey] then
				EquipWeaponSkinEvent:FireServer(selectedWeapon, skin.Id)
			else
				PurchaseWeaponSkinEvent:FireServer(selectedWeapon, skin.Id)
			end
		end)
	end

	WeaponSkinsUpdatedEvent.OnClientEvent:Connect(function(payload)
		state.Coins = payload.Coins
		state.Owned = payload.Owned
		state.Equipped = payload.Equipped
		refreshSkins()
	end)

	refreshWeaponHighlight()
	refreshSkins()

	Localization.OnChanged(function()
		titleLabel.Text = string.upper(Localization.Get("WeaponSkinsSectionTitle"))
		refreshSkins()
	end)
end

return WeaponSkinsUI
