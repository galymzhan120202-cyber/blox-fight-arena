-- Кинематик "режиссёр" камерасы. Тек `launchData=cinematic` арқылы кірген жазушы
-- клиентте іске қосылады. Боттардың төбелесін кадрлайды, ракурсты ауыстырады,
-- соққыда жеңіл шайқалады, өлтіру сәтінде killer-ге жақындап көрсетеді.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local AttackHitEvent = ReplicatedStorage.RemoteEvents:WaitForChild("AttackHit")
local HighlightEvent = ReplicatedStorage.RemoteEvents:WaitForChild("Highlight")

local SHOT_DURATION = 6.5
local CLOSEUP_TIME = 2.3
local BASE_RADIUS = 22
local MIN_RADIUS = 13
local MAX_RADIUS = 40
local MIN_Y = 3.5
local DRIFT_RATE = math.rad(9)
local FOCUS_LERP = 0.09

local CinematicCamera = {}

local function livingBots(): { BasePart }
	local roots = {}
	for _, model in Workspace:GetChildren() do
		if model:IsA("Model") and model.Name:sub(1, 10) == "CombatBot_" then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			local root = model:FindFirstChild("HumanoidRootPart")
			if humanoid and root and humanoid.Health > 0 then
				table.insert(roots, root)
			end
		end
	end
	return roots
end

local function actionPoint(roots: { BasePart }, fallback: Vector3): (Vector3, number)
	if #roots == 0 then
		return fallback, BASE_RADIUS
	end
	if #roots == 1 then
		return roots[1].Position, MIN_RADIUS
	end

	local bestA, bestB, bestDist = roots[1], roots[2], math.huge
	for i = 1, #roots do
		for j = i + 1, #roots do
			local d = (roots[i].Position - roots[j].Position).Magnitude
			if d < bestDist then
				bestA, bestB, bestDist = roots[i], roots[j], d
			end
		end
	end

	local mid = (bestA.Position + bestB.Position) * 0.5
	local spread = 0
	for _, r in roots do
		spread = math.max(spread, (r.Position - mid).Magnitude)
	end
	return mid, math.clamp(BASE_RADIUS + spread * 0.5, MIN_RADIUS, MAX_RADIUS)
end

local function newShot()
	return {
		angle = math.random() * math.pi * 2,
		height = ({ 3.5, 6, 8, 8, 13, 19 })[math.random(1, 6)],
		radiusMul = 0.8 + math.random() * 0.7,
		driftSign = (math.random() < 0.5) and -1 or 1,
		hardCut = math.random() < 0.35,
		startedAt = os.clock(),
	}
end

function CinematicCamera.Init()
	local function activate()
		if LocalPlayer:GetAttribute("Cinematic") ~= true or CinematicCamera._running then
			return
		end
		CinematicCamera._running = true

		local camera = Workspace.CurrentCamera
		while not camera do
			task.wait()
			camera = Workspace.CurrentCamera
		end
		camera.CameraType = Enum.CameraType.Scriptable
		camera.FieldOfView = 60

		for _, name in { "Backpack", "Health", "PlayerList", "Chat", "EmotesMenu", "SelfView" } do
			pcall(function()
				StarterGui:SetCoreGuiEnabled((Enum.CoreGuiType :: any)[name], false)
			end)
		end

		local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
		if playerGui then
			for _, gui in playerGui:GetChildren() do
				if gui:IsA("ScreenGui") then
					gui.Enabled = false
				end
			end
			playerGui.ChildAdded:Connect(function(gui)
				if gui:IsA("ScreenGui") then
					task.defer(function()
						gui.Enabled = false
					end)
				end
			end)
		end

		local focus = Vector3.new(0, 5, 0)
		local shot = newShot()
		local arenaCenter = Vector3.new(0, 6, 0)
		local shakeAmt = 0
		local closeupUntil = 0
		local closeupTarget: BasePart? = nil
		local smoothCF: CFrame? = nil

		-- Соққыда жеңіл шайқалу (фокусқа жақын болса)
		AttackHitEvent.OnClientEvent:Connect(function(targetModel)
			if typeof(targetModel) ~= "Instance" or not targetModel:IsA("Model") then
				return
			end
			local r = targetModel:FindFirstChild("HumanoidRootPart") :: BasePart?
			if r and (r.Position - focus).Magnitude < 45 then
				shakeAmt = math.min(shakeAmt + 0.35, 1.1)
			end
		end)

		-- Өлтіру сәтінде killer-ге жақындау
		HighlightEvent.OnClientEvent:Connect(function(_htype, _desc, _ts, killerModel)
			if typeof(killerModel) == "Instance" and killerModel:IsA("Model") then
				local r = killerModel:FindFirstChild("HumanoidRootPart") :: BasePart?
				if r then
					closeupTarget = r
					closeupUntil = os.clock() + CLOSEUP_TIME
					shakeAmt = math.min(shakeAmt + 0.5, 1.3)
				end
			end
		end)

		RunService:BindToRenderStep("CinematicCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
			local character = LocalPlayer.Character
			if character then
				for _, part in character:GetDescendants() do
					if part:IsA("BasePart") or part:IsA("Decal") then
						part.LocalTransparencyModifier = 1
					end
				end
			end

			local roots = livingBots()
			local target, radius = actionPoint(roots, arenaCenter)
			focus = focus:Lerp(target, FOCUS_LERP)

			local desiredCF: CFrame
			local hardCut = false

			if closeupTarget and closeupTarget.Parent and os.clock() < closeupUntil then
				-- Close-up: killer айналасында төмен драмалық ракурс, баяу орбита
				local subj = closeupTarget.Position
				local orbit = os.clock() * 1.1
				local flat = Vector3.new(math.cos(orbit), 0, math.sin(orbit))
				local pos = subj + flat * 8 + Vector3.new(0, 3, 0)
				desiredCF = CFrame.lookAt(pos, subj + Vector3.new(0, 1.5, 0))
			else
				closeupTarget = nil
				if os.clock() - shot.startedAt > SHOT_DURATION then
					shot = newShot()
				end
				local t = os.clock() - shot.startedAt
				local angle = shot.angle + shot.driftSign * DRIFT_RATE * t
				local r = radius * shot.radiusMul * (1 - 0.08 * (t / SHOT_DURATION))
				local pos = focus + Vector3.new(math.cos(angle) * r, shot.height, math.sin(angle) * r)
				if pos.Y < MIN_Y then
					pos = Vector3.new(pos.X, MIN_Y, pos.Z)
				end
				desiredCF = CFrame.lookAt(pos, focus + Vector3.new(0, 2, 0))
				hardCut = shot.hardCut and t < dt * 2
			end

			-- Жұмсақ монтаж: hard-cut болмаса, CFrame-ге қарай тегіс жылжу
			if smoothCF == nil or hardCut then
				smoothCF = desiredCF
			else
				smoothCF = smoothCF:Lerp(desiredCF, math.clamp(10 * dt, 0, 1))
			end

			-- Шайқалу
			shakeAmt = math.max(0, shakeAmt - dt * 2.2)
			local shakeCF = CFrame.new()
			if shakeAmt > 0.01 then
				local a = shakeAmt
				shakeCF = CFrame.new(
					(math.random() - 0.5) * a * 0.6,
					(math.random() - 0.5) * a * 0.6,
					0
				) * CFrame.Angles(0, 0, (math.random() - 0.5) * a * 0.04)
			end

			camera.CFrame = (smoothCF :: CFrame) * shakeCF
		end)
	end

	activate()
	LocalPlayer:GetAttributeChangedSignal("Cinematic"):Connect(activate)
end

return CinematicCamera
