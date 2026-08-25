local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CosmeticsDatabase = require(ReplicatedStorage.Modules.Data.CosmeticsDatabase)
local PlayerDataService = require(script.Parent.PlayerDataService)

local COSMETIC_TAG = "EquippedSkinVisual"

local PurchaseSkinEvent = ReplicatedStorage.RemoteEvents:WaitForChild("PurchaseSkin")
local EquipSkinEvent = ReplicatedStorage.RemoteEvents:WaitForChild("EquipSkin")
local CosmeticsUpdatedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("CosmeticsUpdated")

local CosmeticsService = {}

local function notifyClient(player: Player)
	local data = PlayerDataService.Get(player)
	if not data then
		return
	end

	CosmeticsUpdatedEvent:FireClient(player, {
		Coins = data.Coins,
		Owned = data.OwnedCosmetics,
		Equipped = data.EquippedSkin,
	})
end

local function applyVisual(character: Model, skinId: string)
	local existing = character:FindFirstChild(COSMETIC_TAG)
	if existing then
		existing:Destroy()
	end

	local skin = CosmeticsDatabase[skinId]
	if not skin then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then
		return
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = COSMETIC_TAG
	highlight.FillTransparency = 1
	highlight.OutlineColor = skin.OutlineColor
	highlight.OutlineTransparency = 0
	highlight.Parent = character

	if skin.Particles then
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = COSMETIC_TAG
		emitter.Color = ColorSequence.new(skin.OutlineColor)
		emitter.Size = NumberSequence.new(0.35)
		emitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(1, 1),
		})
		emitter.Lifetime = NumberRange.new(0.6, 1)
		emitter.Rate = 12
		emitter.Speed = NumberRange.new(1, 2)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Parent = rootPart
	end
end

function CosmeticsService.Purchase(player: Player, skinId: string): boolean
	local skin = CosmeticsDatabase[skinId]
	local data = PlayerDataService.Get(player)
	if not skin or not data then
		return false
	end

	if data.OwnedCosmetics[skinId] then
		return false
	end

	if not PlayerDataService.SpendCoins(player, skin.Price) then
		return false
	end

	data.OwnedCosmetics[skinId] = true
	print(string.format("[Cosmetics] %s '%s' скинін сатып алды (-%d Coins)", player.Name, skin.Name, skin.Price))
	notifyClient(player)

	return true
end

function CosmeticsService.Equip(player: Player, skinId: string): boolean
	local skin = CosmeticsDatabase[skinId]
	local data = PlayerDataService.Get(player)
	if not skin or not data or not data.OwnedCosmetics[skinId] then
		return false
	end

	data.EquippedSkin = skinId

	if player.Character then
		applyVisual(player.Character, skinId)
	end

	notifyClient(player)
	return true
end

function CosmeticsService.Init()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			-- PlayerDataService.PlayerAdded DataStore-ды жүктеп жатқанда бірінші
			-- Character дереу пайда болуы мүмкін (auto-spawn) — сол сәтте деректер
			-- әлі дайын болмай, скин ешқашан тағылмай қалатын жарыс жағдайы болатын.
			local data = PlayerDataService.WaitForData(player)
			if data then
				applyVisual(character, data.EquippedSkin)
			end
			notifyClient(player)
		end)
	end)

	PurchaseSkinEvent.OnServerEvent:Connect(function(player, skinId)
		if typeof(skinId) == "string" then
			CosmeticsService.Purchase(player, skinId)
		end
	end)

	EquipSkinEvent.OnServerEvent:Connect(function(player, skinId)
		if typeof(skinId) == "string" then
			CosmeticsService.Equip(player, skinId)
		end
	end)
end

return CosmeticsService
