local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent.PlayerDataService)
local WeaponModelService = require(script.Parent.WeaponModelService)
local WeaponSkinsDatabase = require(ReplicatedStorage.Modules.Data.WeaponSkinsDatabase)

local VISUAL_MODEL_NAME = "WeaponVisual"

local PurchaseWeaponSkinEvent = ReplicatedStorage.RemoteEvents:WaitForChild("PurchaseWeaponSkin")
local EquipWeaponSkinEvent = ReplicatedStorage.RemoteEvents:WaitForChild("EquipWeaponSkin")
local WeaponSkinsUpdatedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("WeaponSkinsUpdated")

local WeaponSkinService = {}

local function findSkin(skinId: string)
	for _, skin in WeaponSkinsDatabase do
		if skin.Id == skinId then
			return skin
		end
	end
	return nil
end

local function ownedKey(weaponName: string, skinId: string): string
	return weaponName .. "_" .. skinId
end

function WeaponSkinService.GetEquippedSkinId(player: Player, weaponName: string): string
	local data = PlayerDataService.Get(player)
	return (data and data.EquippedWeaponSkins[weaponName]) or "Default"
end

local function notifyClient(player: Player)
	local data = PlayerDataService.Get(player)
	if not data then
		return
	end

	WeaponSkinsUpdatedEvent:FireClient(player, {
		Coins = data.Coins,
		Owned = data.OwnedWeaponSkins,
		Equipped = data.EquippedWeaponSkins,
	})
end

-- Ойыншы дәл қазір сол қаруды қолда ұстап тұрса (WeaponModelService.Equip кезінде
-- қойылған "WeaponName" attribute арқылы анықталады), 3D моделін дереу қайта салады —
-- WeaponService-ті require етпейді (циклдік тәуелділік болмас үшін).
local function refreshIfEquipped(player: Player, weaponName: string, skinId: string)
	local character = player.Character
	local tool = character and character:FindFirstChild(VISUAL_MODEL_NAME) :: Tool?
	if tool and tool:GetAttribute("WeaponName") == weaponName then
		WeaponModelService.Equip(player, character :: Model, weaponName, skinId)
	end
end

function WeaponSkinService.Purchase(player: Player, weaponName: string, skinId: string): boolean
	local skin = findSkin(skinId)
	local data = PlayerDataService.Get(player)
	if not skin or not data or skinId == "Default" then
		return false
	end

	local key = ownedKey(weaponName, skinId)
	if data.OwnedWeaponSkins[key] then
		return false
	end

	if not PlayerDataService.SpendCoins(player, skin.Price) then
		return false
	end

	data.OwnedWeaponSkins[key] = true
	print(string.format("[WeaponSkin] %s '%s' (%s) скинін сатып алды", player.Name, skin.Name, weaponName))
	notifyClient(player)

	return true
end

function WeaponSkinService.Equip(player: Player, weaponName: string, skinId: string): boolean
	local skin = findSkin(skinId)
	local data = PlayerDataService.Get(player)
	if not skin or not data then
		return false
	end

	if skinId ~= "Default" and not data.OwnedWeaponSkins[ownedKey(weaponName, skinId)] then
		return false
	end

	data.EquippedWeaponSkins[weaponName] = skinId
	notifyClient(player)
	refreshIfEquipped(player, weaponName, skinId)

	return true
end

function WeaponSkinService.Init()
	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			PlayerDataService.WaitForData(player)
			notifyClient(player)
		end)
	end)

	PurchaseWeaponSkinEvent.OnServerEvent:Connect(function(player, weaponName, skinId)
		if typeof(weaponName) == "string" and typeof(skinId) == "string" then
			WeaponSkinService.Purchase(player, weaponName, skinId)
		end
	end)

	EquipWeaponSkinEvent.OnServerEvent:Connect(function(player, weaponName, skinId)
		if typeof(weaponName) == "string" and typeof(skinId) == "string" then
			WeaponSkinService.Equip(player, weaponName, skinId)
		end
	end)
end

return WeaponSkinService
