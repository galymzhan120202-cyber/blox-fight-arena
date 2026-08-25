local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local AttackHitEvent = ReplicatedStorage.RemoteEvents:WaitForChild("AttackHit")
local BossSwingEvent = ReplicatedStorage.RemoteEvents:WaitForChild("BossSwing")

local SWING_ANGLE = CFrame.Angles(math.rad(-85), 0, 0)
local SWING_OUT_TIME = 0.1
local SWING_BACK_TIME = 0.15
local HIT_FLASH_TIME = 0.18
local DAMAGE_NUMBER_TIME = 0.6

local CombatVFX = {}

local function playBossSwing()
	local boss = Workspace:FindFirstChild("ArenaBoss")
	local katana = boss and boss:FindFirstChild("BossKatana")
	local hilt = katana and katana.PrimaryPart
	local motor = hilt and hilt:FindFirstChild("BossWeaponGrip") :: Motor6D?
	if not motor then
		return
	end

	local restC0 = motor.C0

	local swingOut = TweenService:Create(
		motor,
		TweenInfo.new(SWING_OUT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ C0 = restC0 * SWING_ANGLE }
	)

	swingOut.Completed:Connect(function()
		TweenService:Create(
			motor,
			TweenInfo.new(SWING_BACK_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ C0 = restC0 }
		):Play()
	end)

	swingOut:Play()
end

local function showDamageNumber(targetModel: Model, damage: number)
	local rootPart = targetModel:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(100, 40)
	billboard.StudsOffset = Vector3.new(math.random(-10, 10) / 10, 2.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = rootPart

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 220, 90)
	label.TextStrokeTransparency = 0.3
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = "-" .. damage
	label.Parent = billboard

	local tween = TweenService:Create(billboard, TweenInfo.new(DAMAGE_NUMBER_TIME, Enum.EasingStyle.Quad), {
		StudsOffset = billboard.StudsOffset + Vector3.new(0, 2, 0),
	})
	TweenService:Create(label, TweenInfo.new(DAMAGE_NUMBER_TIME), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	tween.Completed:Connect(function()
		billboard:Destroy()
	end)
	tween:Play()
end

local function flashHit(targetModel: Instance, damage: number?)
	if not targetModel or not targetModel:IsA("Model") then
		return
	end

	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.fromRGB(255, 60, 60)
	highlight.FillTransparency = 0.35
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.Parent = targetModel

	task.delay(HIT_FLASH_TIME, function()
		highlight:Destroy()
	end)

	if damage then
		showDamageNumber(targetModel :: Model, damage)
	end
end

function CombatVFX.Init()
	AttackHitEvent.OnClientEvent:Connect(flashHit)
	BossSwingEvent.OnClientEvent:Connect(playBossSwing)
end

return CombatVFX
