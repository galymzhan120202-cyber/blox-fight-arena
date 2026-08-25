local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent.PlayerDataService)

local VALID_LANGUAGES = { kk = true, ru = true }

local SetLanguageEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SetLanguage")
local LanguageChangedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("LanguageChanged")

local LanguageService = {}

local function sendCurrent(player: Player)
	local data = PlayerDataService.WaitForData(player)
	LanguageChangedEvent:FireClient(player, (data and data.Language) or "kk")
end

function LanguageService.Init()
	Players.PlayerAdded:Connect(function(player)
		task.spawn(sendCurrent, player)
	end)

	SetLanguageEvent.OnServerEvent:Connect(function(player, language)
		if not VALID_LANGUAGES[language] then
			return
		end

		local data = PlayerDataService.Get(player)
		if not data then
			return
		end

		data.Language = language
		LanguageChangedEvent:FireClient(player, language)
	end)
end

return LanguageService
