local HttpService = game:GetService("HttpService")

-- Discord/webhook сілтемесін осында қойыңыз (жоба publish етілгеннен кейін).
-- Бос болса, әрбір "қызықты сәт" тек Output-қа уақыт белгісімен жазылады.
local WEBHOOK_URL = ""

local HighlightService = {}

local function postWebhook(text: string)
	if WEBHOOK_URL == "" then
		return
	end

	local ok, err = pcall(function()
		HttpService:PostAsync(WEBHOOK_URL, HttpService:JSONEncode({ content = text }))
	end)

	if not ok then
		warn("[HighlightService] Webhook жіберілмеді: " .. tostring(err))
	end
end

function HighlightService.Log(highlightType: string, description: string)
	local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")

	print(string.format("[Highlight] [%s] %s: %s", timestamp, highlightType, description))
	postWebhook(string.format("🎬 **%s** — %s (%s)", highlightType, description, timestamp))
end

return HighlightService
