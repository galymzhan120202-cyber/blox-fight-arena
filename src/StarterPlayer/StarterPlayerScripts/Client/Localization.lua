local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Strings = require(ReplicatedStorage.Modules.Data.Strings)

local SetLanguageEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SetLanguage")
local LanguageChangedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("LanguageChanged")

local Localization = {}

local currentLanguage = "kk"
local listeners = {}

local function notifyListeners()
	for _, callback in listeners do
		task.spawn(callback)
	end
end

-- Кілт табылмаса — қазақшаға, одан кейін кілттің өзіне түседі (крашпен бұзылмас үшін).
function Localization.Get(key: string, ...: any): string
	local strings = Strings[currentLanguage] or Strings.kk
	local template = strings[key] or Strings.kk[key] or key

	local args = { ... }
	if #args == 0 then
		return template
	end

	return string.format(template, ...)
end

function Localization.GetLanguage(): string
	return currentLanguage
end

function Localization.SetLanguage(language: string)
	if language ~= "kk" and language ~= "ru" then
		return
	end

	SetLanguageEvent:FireServer(language)

	if language ~= currentLanguage then
		currentLanguage = language
		notifyListeners()
	end
end

-- UI бөлімдері осы арқылы тіркеліп, тіл ауысқанда өз мәтінін қайта салады.
function Localization.OnChanged(callback: () -> ())
	table.insert(listeners, callback)
end

function Localization.Init()
	LanguageChangedEvent.OnClientEvent:Connect(function(language: string)
		if (language == "kk" or language == "ru") and language ~= currentLanguage then
			currentLanguage = language
			notifyListeners()
		end
	end)
end

return Localization
