local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Тұрақты webhook міндетті емес. Кинематик режим қосылғанда CinematicService
-- `HighlightService.SetSink(url)` арқылы жергілікті clipper демонының мекенжайын
-- береді; қалыпты серверлерде sink бос болып, тек Output-қа жазылады.
--
-- ЕСКЕРТУ: HttpService нақты Roblox серверінде жұмыс істейді — жазушы машинаға
-- localhost арқылы жете алмайды. Сондықтан кинематик түсіруде негізгі арна —
-- `Highlight` RemoteEvent → клиент маркер басып шығарады → clipper Roblox
-- логынан оқиды (automation/capture қараңыз). Webhook тек Studio/Discord үшін.
local WEBHOOK_URL = ""
local runtimeSink: string? = nil

local HighlightEvent = ReplicatedStorage.RemoteEvents:WaitForChild("Highlight")

local HighlightService = {}

function HighlightService.SetSink(url: string?)
	runtimeSink = url
end

local function postWebhook(payload: { [string]: any })
	local target = runtimeSink ~= nil and runtimeSink ~= "" and runtimeSink or WEBHOOK_URL
	if target == "" then
		return
	end

	local ok, err = pcall(function()
		HttpService:PostAsync(target, HttpService:JSONEncode(payload))
	end)

	if not ok then
		warn("[HighlightService] Webhook жіберілмеді: " .. tostring(err))
	end
end

-- extra (міндетті емес): { killer = Model?, victim = Model? } — кинематик камера
-- өлтіру сәтінде killer-ге жақындап көрсету үшін пайдаланады.
function HighlightService.Log(highlightType: string, description: string, extra: { killer: Model?, victim: Model? }?)
	local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")

	print(string.format("[Highlight] [%s] %s: %s", timestamp, highlightType, description))

	-- Клиенттер маркер басып шығарсын (clipper Roblox логынан осыны іздейді).
	local killer = extra and extra.killer or nil
	local victim = extra and extra.victim or nil
	HighlightEvent:FireAllClients(highlightType, description, timestamp, killer, victim)

	postWebhook({
		content = string.format("🎬 **%s** — %s (%s)", highlightType, description, timestamp),
		type = highlightType,
		description = description,
		timestamp = timestamp,
	})
end

return HighlightService
