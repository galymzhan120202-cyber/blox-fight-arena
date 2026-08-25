local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent.PlayerDataService)
local RankService = require(script.Parent.RankService)
local WeaponService = require(script.Parent.WeaponService)
local WeaponModelService = require(script.Parent.WeaponModelService)
local MatchModeService = require(script.Parent.MatchModeService)
local NotificationService = require(script.Parent.NotificationService)
local HighlightService = require(script.Parent.HighlightService)
local MonetizationService = require(script.Parent.MonetizationService)
local RoundService = require(script.Parent.RoundService)
local BossService = require(script.Parent.BossService)

local DAMAGEABLE_TAG = "Damageable"
local HIT_XP = 10
local KILL_XP = 25
local HIT_COINS = 2
local KILL_COINS = 15
local KILLSTREAK_BONUS_COINS = 20
local KNOCKBACK_FORCE = 45
local KNOCKBACK_UP = 10

local KILLSTREAK_MESSAGES = {
	[3] = "ҮШТІК ЖЕҢІС",
	[5] = "БЕСТІК ШАБУЫЛ",
	[7] = "ТОҚТАТЫЛМАЙДЫ",
	[10] = "ЛЕГЕНДА",
}

local UseAbilityEvent = ReplicatedStorage.RemoteEvents:WaitForChild("UseAbility")
local AttackHitEvent = ReplicatedStorage.RemoteEvents:WaitForChild("AttackHit")

local CombatService = {}

local lastAbilityUse = {}
local killStreaks = {}
local lastKilledBy = {}
local firstBloodClaimed = false

local function isOnCooldown(player: Player, cooldown: number): boolean
	local lastUse = lastAbilityUse[player]
	return lastUse ~= nil and (os.clock() - lastUse) < cooldown
end

local function getHumanoidRootPart(character: Model?): BasePart?
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function applyKnockback(victimRoot: BasePart, attackerRoot: BasePart)
	local direction = victimRoot.Position - attackerRoot.Position
	direction = Vector3.new(direction.X, 0, direction.Z)
	if direction.Magnitude > 0 then
		direction = direction.Unit
	end

	victimRoot.AssemblyLinearVelocity = direction * KNOCKBACK_FORCE + Vector3.new(0, KNOCKBACK_UP, 0)
end

local function onUseAbility(player: Player)
	local weapon = WeaponService.GetPlayerWeapon(player)
	if not weapon then
		return
	end

	if isOnCooldown(player, weapon.Cooldown) then
		return
	end

	local rootPart = getHumanoidRootPart(player.Character)
	if not rootPart then
		return
	end

	local mode = MatchModeService.GetMode()

	-- FFA/Team режимінде раунд басталмағанша шабуыл өтпейді (дайындық фазасы қауіпсіз).
	-- Boss/Training режимдері раунд тұжырымдамасына тәуелсіз — олар өз бетінше қосылады.
	if (mode == "FFA" or mode == "Team") and not RoundService.IsActive() then
		return
	end

	lastAbilityUse[player] = os.clock()
	WeaponModelService.PlaySwing(player.Character)

	local eligible = {}
	for _, targetModel in CollectionService:GetTagged(DAMAGEABLE_TAG) do
		if targetModel == player.Character then
			continue
		end

		local targetPlayer = Players:GetPlayerFromCharacter(targetModel)
		if targetPlayer then
			if mode == "Boss" or mode == "Training" then
				continue
			end
			if mode == "Team" and MatchModeService.IsSameTeam(player, targetPlayer) then
				continue
			end
		end

		local otherRoot = getHumanoidRootPart(targetModel)
		local humanoid = targetModel:FindFirstChild("Humanoid") :: Humanoid?
		if not otherRoot or not humanoid or humanoid.Health <= 0 then
			continue
		end

		local offset = otherRoot.Position - rootPart.Position
		local distance = offset.Magnitude
		if distance > weapon.Range then
			continue
		end

		local toTarget = offset.Unit
		local facing = rootPart.CFrame.LookVector
		if toTarget:Dot(facing) < 0.3 then
			continue
		end

		table.insert(eligible, {
			model = targetModel,
			player = targetPlayer,
			root = otherRoot,
			humanoid = humanoid,
			distance = distance,
		})
	end

	-- Ұзын қашықтықты қарулар (Range-і ұзын, SingleTarget=true) тек ең жақын нысанаға тиеді;
	-- жақынтабан қарулар (Sword/Daggers/т.б.) бұрынғыдай доғадағы барлығына тиеді (cleave).
	if weapon.SingleTarget and #eligible > 1 then
		table.sort(eligible, function(a, b)
			return a.distance < b.distance
		end)
		eligible = { eligible[1] }
	end

	for _, target in eligible do
		local targetModel, targetPlayer, otherRoot, humanoid = target.model, target.player, target.root, target.humanoid

		humanoid:TakeDamage(weapon.Damage)
		AttackHitEvent:FireAllClients(targetModel, weapon.Damage)
		applyKnockback(otherRoot, rootPart)

		if CollectionService:HasTag(targetModel, "Boss") then
			BossService.RecordParticipant(player)
		end

		PlayerDataService.AddXP(player, MonetizationService.ApplyVipMultiplier(HIT_XP, player))
		PlayerDataService.AddCoins(player, MonetizationService.ApplyVipMultiplier(HIT_COINS, player))

		if humanoid.Health <= 0 then
			PlayerDataService.AddXP(player, MonetizationService.ApplyVipMultiplier(KILL_XP, player))
			PlayerDataService.AddCoins(player, MonetizationService.ApplyVipMultiplier(KILL_COINS, player))
			PlayerDataService.IncrementStat(player, "Kills", 1)

			local isBot = CollectionService:HasTag(targetModel, "Bot")

			if targetPlayer or isBot then
				local victimName = targetPlayer and targetPlayer.Name or targetModel.Name

				RankService.AwardKill(player)

				if targetPlayer then
					RankService.PenalizeDeath(targetPlayer)
					PlayerDataService.IncrementStat(targetPlayer, "Deaths", 1)
					killStreaks[targetPlayer] = 0
					NotificationService.Toast(
						targetPlayer,
						string.format("%s сізді жеңді!", player.Name),
						Color3.fromRGB(255, 120, 120)
					)
				end

				killStreaks[player] = (killStreaks[player] or 0) + 1
				local streak = killStreaks[player]

				NotificationService.Feed(string.format("%s ➤ %s", player.Name, victimName))

				if not firstBloodClaimed then
					firstBloodClaimed = true
					NotificationService.ToastAll(
						string.format("АЛҒАШҚЫ ҚАН — %s!", player.Name),
						Color3.fromRGB(255, 90, 90)
					)
					HighlightService.Log("Алғашқы қан", string.format("%s алғашқы өлтіруді жасады", player.Name))
				end

				if targetPlayer and lastKilledBy[player] == targetPlayer then
					NotificationService.ToastAll(
						string.format("%s КЕК АЛДЫ!", player.Name),
						Color3.fromRGB(200, 120, 255)
					)
					PlayerDataService.AddCoins(player, KILLSTREAK_BONUS_COINS)
					HighlightService.Log("Кек", string.format("%s → %s кегін алды", player.Name, targetPlayer.Name))
				end
				if targetPlayer then
					lastKilledBy[targetPlayer] = player
				end

				local streakMessage = KILLSTREAK_MESSAGES[streak]
				if streakMessage then
					NotificationService.ToastAll(
						string.format("%s — %s (%dx)!", player.Name, streakMessage, streak),
						Color3.fromRGB(255, 200, 60)
					)
					PlayerDataService.AddCoins(player, KILLSTREAK_BONUS_COINS)
					HighlightService.Log("Killstreak", string.format("%s — %s (%dx)", player.Name, streakMessage, streak))
				end
			end
		end
	end
end

function CombatService.Init()
	UseAbilityEvent.OnServerEvent:Connect(onUseAbility)

	Players.PlayerRemoving:Connect(function(player)
		lastAbilityUse[player] = nil
		killStreaks[player] = nil
		lastKilledBy[player] = nil

		for victim, killer in lastKilledBy do
			if killer == player then
				lastKilledBy[victim] = nil
			end
		end
	end)
end

return CombatService
