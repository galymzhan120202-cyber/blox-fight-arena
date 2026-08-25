local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuUI = require(script.Parent.MenuUI)
local Localization = require(script.Parent.Localization)
local CosmeticsDatabase = require(ReplicatedStorage.Modules.Data.CosmeticsDatabase)

local PurchaseSkinEvent = ReplicatedStorage.RemoteEvents:WaitForChild("PurchaseSkin")
local EquipSkinEvent = ReplicatedStorage.RemoteEvents:WaitForChild("EquipSkin")
local CosmeticsUpdatedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("CosmeticsUpdated")

local SKIN_ORDER = { "Default", "Crimson", "Azure", "Toxic", "Gold", "Void" }

local CosmeticsUI = {}

function CosmeticsUI.Init()
	local holder, titleLabel = MenuUI.AddSection(Localization.Get("ShopSectionTitle"), "Дүкен")

	local coinsLabel = MenuUI.CreateButton(holder, "")
	coinsLabel.Active = false
	coinsLabel.AutoButtonColor = false

	local buttons = {}
	local state = { Coins = 0, Owned = {}, Equipped = "Default" }

	local function refresh()
		coinsLabel.Text = Localization.Get("CoinsLabel", state.Coins)

		for skinId, button in buttons do
			local skin = CosmeticsDatabase[skinId]
			local owned = state.Owned[skinId]
			local equipped = state.Equipped == skinId

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

	for _, skinId in SKIN_ORDER do
		local skin = CosmeticsDatabase[skinId]
		local button = MenuUI.CreateButton(holder, skin.Name)
		buttons[skinId] = button

		button.MouseButton1Click:Connect(function()
			if state.Owned[skinId] then
				EquipSkinEvent:FireServer(skinId)
			else
				PurchaseSkinEvent:FireServer(skinId)
			end
		end)
	end

	CosmeticsUpdatedEvent.OnClientEvent:Connect(function(payload)
		state.Coins = payload.Coins
		state.Owned = payload.Owned
		state.Equipped = payload.Equipped
		refresh()
	end)

	refresh()

	Localization.OnChanged(function()
		titleLabel.Text = string.upper(Localization.Get("ShopSectionTitle"))
		refresh()
	end)
end

return CosmeticsUI
