-- Кинематик режим: `launchData=cinematic` арқылы кірген жазушы клиент серверде
-- тек боттардан тұратын шексіз матч бастайды. Нақты ойыншылар кіретін
-- қалыпты серверлерге ЕШҚАНДАЙ әсері жоқ (LaunchData тек біздің launcher береді).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local BotService = require(script.Parent.BotService)
local RoundService = require(script.Parent.RoundService)
local HighlightService = require(script.Parent.HighlightService)

local LAUNCH_KEY = "cinematic"
local CINEMATIC_BOTS = 6
local ROUND_LENGTH = 95 -- бір "раунд" ұзақтығы (сек); соңында highlight күйі жаңарады
local INTERMISSION = 3
-- Жергілікті clipper демоны (жазушы машинада localhost).
local CLIPPER_SINK = "http://127.0.0.1:8790/highlight"

local CinematicService = {}

local activeRecorder: Player? = nil
local loopToken = 0

local function stripCharacter(player: Player)
	-- Жазушының аватары аренада тұрмас үшін (боттар да оны елемейді — BotService).
	local character = player.Character
	if character then
		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			root.CFrame = CFrame.new(0, -500, 0)
			root.Anchored = true
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
	end
end

local function runMatchLoop(token: number)
	task.spawn(function()
		BotService.SetCount(CINEMATIC_BOTS)

		while loopToken == token and activeRecorder and activeRecorder.Parent do
			RoundService.SetActive(false)
			task.wait(INTERMISSION)
			if loopToken ~= token then
				break
			end

			-- Боттарды қайта араластыру (жаңа спавн орындары, HP толы).
			BotService.SetCount(0)
			task.wait(0.6)
			BotService.SetCount(CINEMATIC_BOTS)

			RoundService.SetActive(true)
			task.wait(ROUND_LENGTH)
		end
	end)
end

local function startCinematic(player: Player)
	if activeRecorder then
		return -- бір мезгілде бір ғана кинематик сессия
	end

	activeRecorder = player
	player:SetAttribute("Cinematic", true)
	HighlightService.SetSink(CLIPPER_SINK)

	player.CharacterAdded:Connect(function()
		task.wait(0.1)
		if activeRecorder == player then
			stripCharacter(player)
		end
	end)
	stripCharacter(player)

	loopToken += 1
	runMatchLoop(loopToken)

	print("[Cinematic] Режим қосылды — жазушы: " .. player.Name)
end

local function stopCinematic()
	if not activeRecorder then
		return
	end

	loopToken += 1
	activeRecorder = nil
	HighlightService.SetSink(nil)
	RoundService.SetActive(false)
	BotService.SetCount(0)

	print("[Cinematic] Режим тоқтады")
end

local function considerPlayer(player: Player)
	if activeRecorder then
		return
	end

	local ok, joinData = pcall(function()
		return player:GetJoinData()
	end)
	local launchData = ok and joinData and joinData.LaunchData or nil

	-- Триггер: launchData=cinematic (launcher береді) НЕМЕСЕ Workspace.CinematicMode
	-- атрибуты (Studio-да қолмен тексеру / балама іске қосу үшін).
	if launchData == LAUNCH_KEY or Workspace:GetAttribute("CinematicMode") == true then
		startCinematic(player)
	end
end

function CinematicService.Init()
	Players.PlayerAdded:Connect(considerPlayer)
	for _, player in Players:GetPlayers() do
		considerPlayer(player)
	end

	Workspace:GetAttributeChangedSignal("CinematicMode"):Connect(function()
		if Workspace:GetAttribute("CinematicMode") == true then
			local first = Players:GetPlayers()[1]
			if first then
				considerPlayer(first)
			end
		elseif activeRecorder then
			stopCinematic()
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		if player == activeRecorder then
			stopCinematic()
		end
	end)
end

return CinematicService
