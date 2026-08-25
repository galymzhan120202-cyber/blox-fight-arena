local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local UseAbilityEvent = ReplicatedStorage.RemoteEvents:WaitForChild("UseAbility")

local CombatController = {}

local ATTACK_KEY = Enum.KeyCode.F

function CombatController.Init()
	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then
			return
		end

		if input.KeyCode == ATTACK_KEY or input.UserInputType == Enum.UserInputType.MouseButton1 then
			UseAbilityEvent:FireServer()
		end
	end)
end

return CombatController
