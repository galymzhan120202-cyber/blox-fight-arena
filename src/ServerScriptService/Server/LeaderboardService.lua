local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent.PlayerDataService)

local UPDATE_INTERVAL = 60

local RequestLeaderboardEvent = ReplicatedStorage.RemoteEvents:WaitForChild("RequestLeaderboard")
local LeaderboardDataEvent = ReplicatedStorage.RemoteEvents:WaitForChild("LeaderboardData")

local LeaderboardService = {}

local orderedStoreOk, orderedStore = pcall(function()
	return DataStoreService:GetOrderedDataStore("RankLeaderboard_v1")
end)

if not orderedStoreOk then
	orderedStore = nil
	warn("[LeaderboardService] OrderedDataStore қолжетімсіз (жоба publish етілмеген): жаһандық рейтинг сақталмайды.")
end

local function updateEntry(player: Player)
	if not orderedStore then
		return
	end

	local data = PlayerDataService.Get(player)
	if not data then
		return
	end

	pcall(function()
		orderedStore:SetAsync("Player_" .. player.UserId, data.RankPoints)
	end)
end

local function getLiveTopPlayers(count: number)
	local entries = {}

	for _, player in Players:GetPlayers() do
		local data = PlayerDataService.Get(player)
		if data then
			table.insert(entries, { Name = player.Name, RankPoints = data.RankPoints })
		end
	end

	table.sort(entries, function(a, b)
		return a.RankPoints > b.RankPoints
	end)

	local limited = {}
	for index = 1, math.min(count, #entries) do
		table.insert(limited, entries[index])
	end

	return limited
end

function LeaderboardService.GetTopPlayers(count: number)
	if orderedStore then
		local success, pages = pcall(function()
			return orderedStore:GetSortedAsync(false, count)
		end)

		if success then
			local entries = {}
			for _, entry in pages:GetCurrentPage() do
				local userId = tonumber(string.match(entry.key, "%d+"))
				local nameOk, name = pcall(function()
					return Players:GetNameFromUserIdAsync(userId)
				end)
				table.insert(entries, {
					Name = nameOk and name or entry.key,
					RankPoints = entry.value,
				})
			end

			if #entries > 0 then
				return entries
			end
		end
	end

	return getLiveTopPlayers(count)
end

function LeaderboardService.Init()
	Players.PlayerRemoving:Connect(updateEntry)

	RequestLeaderboardEvent.OnServerEvent:Connect(function(player)
		LeaderboardDataEvent:FireClient(player, LeaderboardService.GetTopPlayers(10))
	end)

	task.spawn(function()
		while true do
			task.wait(UPDATE_INTERVAL)
			for _, player in Players:GetPlayers() do
				updateEntry(player)
			end
		end
	end)
end

return LeaderboardService
