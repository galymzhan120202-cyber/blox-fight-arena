local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent.PlayerDataService)
local CosmeticsDatabase = require(ReplicatedStorage.Modules.Data.CosmeticsDatabase)

-- Roblox Creator Dashboard-тан алынатын нақты ID-лер. Жоба publish етілгенше 0 —
-- ProcessReceipt/UserOwnsGamePassAsync шақыруларына нақты сатып алу келмейді.
--
-- Ұсынылатын баптау (Creator Dashboard → Monetization):
--   Gamepass "VIP"        — XP/Coins +20%, VIP жапсырма   — ~99 Robux
--   Gamepass "AllSkins"   — барлық скинді бірден ашады    — ~149 Robux
--   Product  500 Coins    — ~49 Robux
--   Product  1500 Coins   — ~99 Robux
--   Product  5000 Coins   — ~299 Robux
local GAMEPASS_IDS = {
	VIP = 0,
	AllSkins = 0,
}

-- ЕСКЕРТУ: барлық үш Developer Product-тың нақты ID-ін Creator Dashboard-тан алып,
-- осында толтырыңыз. Map етілмеген ProductId келсе, processReceipt енді Coins
-- бермей, NotProcessedYet қайтарады (Robux алынып, сыйақы жоғалып кетпес үшін).
local PRODUCT_COINS = {
	-- [123456] = 500,  -- "500 Coins"
	-- [123457] = 1500, -- "1500 Coins"
	-- [123458] = 5000, -- "5000 Coins"
}

local VIP_MULTIPLIER = 1.2

local MonetizationService = {}

local vipCache = {}

function MonetizationService.IsVIP(player: Player): boolean
	return vipCache[player] == true
end

function MonetizationService.PlayerOwnsGamepass(player: Player, gamepassName: string): boolean
	local gamepassId = GAMEPASS_IDS[gamepassName]
	if not gamepassId or gamepassId == 0 then
		return false
	end

	local success, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
	end)

	return success and owns == true
end

local function applyOwnedGamepasses(player: Player)
	vipCache[player] = MonetizationService.PlayerOwnsGamepass(player, "VIP")

	if MonetizationService.PlayerOwnsGamepass(player, "AllSkins") then
		local data = PlayerDataService.WaitForData(player)
		if data then
			for skinId in CosmeticsDatabase do
				data.OwnedCosmetics[skinId] = true
			end
		end
	end
end

function MonetizationService.ApplyVipMultiplier(amount: number, player: Player): number
	if MonetizationService.IsVIP(player) then
		return math.floor(amount * VIP_MULTIPLIER)
	end
	return amount
end

local function processReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local coinAmount = PRODUCT_COINS[receiptInfo.ProductId]
	if not coinAmount then
		warn(
			string.format(
				"[Monetization] Белгісіз ProductId=%d (%s) — PRODUCT_COINS-те жоқ, сыйақы берілмеді",
				receiptInfo.ProductId,
				player.Name
			)
		)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	PlayerDataService.AddCoins(player, coinAmount)
	print(
		string.format(
			"[Monetization] %s +%d Coins сатып алды (ProductId=%d)",
			player.Name,
			coinAmount,
			receiptInfo.ProductId
		)
	)

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MonetizationService.Init()
	MarketplaceService.ProcessReceipt = processReceipt

	Players.PlayerAdded:Connect(function(player)
		task.spawn(applyOwnedGamepasses, player)
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
		if wasPurchased then
			applyOwnedGamepasses(player)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		vipCache[player] = nil
	end)
end

return MonetizationService
