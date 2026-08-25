local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent.PlayerDataService)

local MIN_NAME_LENGTH = 3
local MAX_NAME_LENGTH = 20

local ClanCreateEvent = ReplicatedStorage.RemoteEvents:WaitForChild("ClanCreate")
local ClanJoinEvent = ReplicatedStorage.RemoteEvents:WaitForChild("ClanJoin")
local ClanLeaveEvent = ReplicatedStorage.RemoteEvents:WaitForChild("ClanLeave")
local ClanUpdatedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("ClanUpdated")

local ClanService = {}

local dataStoreOk, dataStore = pcall(function()
	return DataStoreService:GetDataStore("Clans_v1")
end)

if not dataStoreOk then
	dataStore = nil
	warn("[ClanService] DataStore қолжетімсіз (жоба publish етілмеген): кландар тек осы сессия ішінде сақталады.")
end

local sessionClans = {}

local function normalizeKey(name: string): string
	return string.lower(name)
end

local function isValidName(name: string): boolean
	local length = #name
	return length >= MIN_NAME_LENGTH and length <= MAX_NAME_LENGTH and string.match(name, "^[%w%s]+$") ~= nil
end

local function loadClan(key: string)
	if sessionClans[key] then
		return sessionClans[key]
	end

	if dataStore then
		local success, result = pcall(function()
			return dataStore:GetAsync(key)
		end)
		if success and result then
			sessionClans[key] = result
			return result
		end
	end

	return nil
end

local function saveClan(key: string, clan)
	sessionClans[key] = clan

	if dataStore then
		pcall(function()
			dataStore:SetAsync(key, clan)
		end)
	end
end

local function notifyClient(player: Player)
	local data = PlayerDataService.Get(player)
	if not data then
		return
	end

	local memberCount = 0
	if data.ClanName then
		local clan = loadClan(normalizeKey(data.ClanName))
		memberCount = clan and #clan.Members or 0
	end

	ClanUpdatedEvent:FireClient(player, {
		ClanName = data.ClanName,
		MemberCount = memberCount,
	})
end

function ClanService.Create(player: Player, name: string)
	local data = PlayerDataService.Get(player)
	if not data or data.ClanName then
		return
	end

	if not isValidName(name) then
		return
	end

	local key = normalizeKey(name)
	if loadClan(key) then
		return
	end

	saveClan(key, { DisplayName = name, Members = { player.UserId } })
	data.ClanName = name

	print(string.format("[Clan] %s '%s' кланын құрды", player.Name, name))
	notifyClient(player)
end

function ClanService.Join(player: Player, name: string)
	local data = PlayerDataService.Get(player)
	if not data or data.ClanName then
		return
	end

	local key = normalizeKey(name)
	local clan = loadClan(key)
	if not clan then
		return
	end

	if not table.find(clan.Members, player.UserId) then
		table.insert(clan.Members, player.UserId)
		saveClan(key, clan)
	end

	data.ClanName = clan.DisplayName
	print(string.format("[Clan] %s '%s' кланына қосылды", player.Name, clan.DisplayName))
	notifyClient(player)
end

function ClanService.Leave(player: Player)
	local data = PlayerDataService.Get(player)
	if not data or not data.ClanName then
		return
	end

	local key = normalizeKey(data.ClanName)
	local clan = loadClan(key)
	if clan then
		local index = table.find(clan.Members, player.UserId)
		if index then
			table.remove(clan.Members, index)
			saveClan(key, clan)
		end
	end

	print(string.format("[Clan] %s '%s' кланынан шықты", player.Name, data.ClanName))
	data.ClanName = nil
	notifyClient(player)
end

function ClanService.Init()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			notifyClient(player)
		end)
	end)

	ClanCreateEvent.OnServerEvent:Connect(function(player, name)
		if typeof(name) == "string" then
			ClanService.Create(player, name)
		end
	end)

	ClanJoinEvent.OnServerEvent:Connect(function(player, name)
		if typeof(name) == "string" then
			ClanService.Join(player, name)
		end
	end)

	ClanLeaveEvent.OnServerEvent:Connect(function(player)
		ClanService.Leave(player)
	end)
end

return ClanService
