local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local NotificationService = require(script.Parent.NotificationService)

local EVENT_INTERVAL = 90
local EVENT_DURATION = 20
local METEOR_TICK = 3
local METEOR_DAMAGE = 8
local METEOR_FALL_TIME = 1

local meteorLoopActive = false

local function strikeMeteor()
	local players = Players:GetPlayers()
	if #players == 0 then
		return
	end

	local target = players[math.random(1, #players)]
	local character = target.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChild("Humanoid") :: Humanoid?
	if not rootPart or not humanoid or humanoid.Health <= 0 then
		return
	end

	local groundPosition = rootPart.Position

	local meteor = Instance.new("Part")
	meteor.Name = "Meteor"
	meteor.Shape = Enum.PartType.Ball
	meteor.Size = Vector3.new(2, 2, 2)
	meteor.Position = groundPosition + Vector3.new(0, 40, 0)
	meteor.Anchored = true
	meteor.CanCollide = false
	meteor.Material = Enum.Material.Neon
	meteor.BrickColor = BrickColor.new("Really orange")
	meteor.Parent = Workspace

	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 140, 40)
	glow.Range = 16
	glow.Brightness = 3
	glow.Parent = meteor

	local tween = TweenService:Create(
		meteor,
		TweenInfo.new(METEOR_FALL_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = groundPosition }
	)

	tween.Completed:Connect(function()
		meteor:Destroy()

		if humanoid.Health > 0 then
			humanoid:TakeDamage(METEOR_DAMAGE)
		end
	end)

	tween:Play()
end

local EVENTS = {
	{
		Name = "Қалың тұман",
		Apply = function()
			Lighting.FogEnd = 60
			Lighting.FogColor = Color3.fromRGB(180, 180, 190)
		end,
		Revert = function()
			Lighting.FogEnd = 100000
		end,
	},
	{
		Name = "Қараңғы түн",
		Apply = function()
			Lighting.Brightness = 0.5
			Lighting.ClockTime = 0
		end,
		Revert = function()
			Lighting.Brightness = 2
			Lighting.ClockTime = 16
		end,
	},
	{
		Name = "Метеорит жаңбыры",
		Apply = function()
			meteorLoopActive = true
			task.spawn(function()
				while meteorLoopActive do
					strikeMeteor()
					task.wait(METEOR_TICK)
				end
			end)
		end,
		Revert = function()
			meteorLoopActive = false
		end,
	},
}

local DynamicEventService = {}

function DynamicEventService.Init()
	task.spawn(function()
		while true do
			task.wait(EVENT_INTERVAL)

			local event = EVENTS[math.random(1, #EVENTS)]
			print(string.format("[Event] %s басталды", event.Name))
			NotificationService.ToastAll(string.format("ОҚИҒА: %s!", event.Name), Color3.fromRGB(255, 150, 60))
			event.Apply()

			task.wait(EVENT_DURATION)

			event.Revert()
			print(string.format("[Event] %s аяқталды", event.Name))
		end
	end)
end

return DynamicEventService
