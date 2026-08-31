-- Кинематик жазу кезінде highlight сәттерін Roblox клиент логына парсерленетін
-- жолмен басып шығарады. Clipper демоны (automation/capture) осы жолдарды
-- лог файлынан оқып, ffmpeg-пен клип кеседі. Тек `Cinematic` атрибуты бар
-- жазушы клиентте жұмыс істейді — қалыпты ойыншылардың логын ластамайды.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local HighlightEvent = ReplicatedStorage.RemoteEvents:WaitForChild("Highlight")

local MARKER = "__BFA_HIGHLIGHT__"

local CinematicMarkers = {}

function CinematicMarkers.Init()
	HighlightEvent.OnClientEvent:Connect(function(highlightType, description, timestamp)
		if LocalPlayer:GetAttribute("Cinematic") ~= true then
			return
		end

		local line = HttpService:JSONEncode({
			type = highlightType,
			description = description,
			timestamp = timestamp,
		})
		print(MARKER .. " " .. line)
	end)
end

return CinematicMarkers
