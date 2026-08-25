local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ADMIN_USER_IDS = {
	-- [123456789] = true, -- қосымша админдерді осында UserId бойынша қосыңыз
}

local AdminService = {}

function AdminService.IsAdmin(player: Player): boolean
	if RunService:IsStudio() then
		-- Studio-да ойынды тестілеу (Play/Team Create) әрдайым сенімді орта —
		-- жарияланбаған жобада game.CreatorId бос/сәйкессіз болады да, нақты
		-- админ тексеруі тестерді дұрыс таппай қалады.
		return true
	end

	if ADMIN_USER_IDS[player.UserId] then
		return true
	end

	if game.CreatorType == Enum.CreatorType.User then
		return player.UserId == game.CreatorId
	end

	if game.CreatorType == Enum.CreatorType.Group then
		local ok, rank = pcall(function()
			return player:GetRankInGroup(game.CreatorId)
		end)
		return ok and rank >= 200
	end

	return false
end

return AdminService
