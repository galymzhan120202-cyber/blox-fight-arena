local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.UITheme)

local SetRoundActiveEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SetRoundActive")
local RoundChangedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("RoundChanged")

local START_COLOR = Color3.fromRGB(90, 200, 140)
local STOP_COLOR = Color3.fromRGB(220, 80, 80)

local RoundUI = {}

local player = Players.LocalPlayer

function RoundUI.Init()
	local playerGui = player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "RoundGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local button = Instance.new("TextButton")
	button.Name = "RoundToggle"
	button.AnchorPoint = Vector2.new(0.5, 0)
	button.Position = UDim2.new(0.5, 0, 0, 16)
	button.Size = UDim2.fromOffset(220, 40)
	button.BackgroundColor3 = START_COLOR
	button.TextColor3 = Color3.fromRGB(15, 20, 15)
	button.Font = Theme.TitleFont
	button.TextSize = 16
	button.Text = "Раундты бастау"
	button.AutoButtonColor = false
	button.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = Theme.CornerRadius
	corner.Parent = button

	local roundActive = false

	button.MouseButton1Click:Connect(function()
		SetRoundActiveEvent:FireServer(not roundActive)
	end)

	RoundChangedEvent.OnClientEvent:Connect(function(active: boolean)
		roundActive = active

		if active then
			button.Text = "Раунд жүріп жатыр — тоқтату"
			button.BackgroundColor3 = STOP_COLOR
			button.TextColor3 = Color3.fromRGB(255, 245, 245)
		else
			button.Text = "Раундты бастау"
			button.BackgroundColor3 = START_COLOR
			button.TextColor3 = Color3.fromRGB(15, 20, 15)
		end
	end)
end

return RoundUI
