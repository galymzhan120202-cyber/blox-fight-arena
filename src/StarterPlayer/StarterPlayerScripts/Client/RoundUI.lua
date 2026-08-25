local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuUI = require(script.Parent.MenuUI)
local Theme = require(script.Parent.UITheme)
local Localization = require(script.Parent.Localization)

local SetRoundActiveEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SetRoundActive")
local RoundChangedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("RoundChanged")

local START_COLOR = Color3.fromRGB(90, 200, 140)
local STOP_COLOR = Color3.fromRGB(220, 80, 80)

local RoundUI = {}

function RoundUI.Init()
	local holder, titleLabel = MenuUI.AddSection(Localization.Get("StartSectionTitle"))

	local button = MenuUI.CreateButton(holder, Localization.Get("RoundStart"))
	button.BackgroundColor3 = START_COLOR
	button.TextColor3 = Color3.fromRGB(15, 20, 15)
	button.Font = Theme.TitleFont
	button.Size = UDim2.new(1, 0, 0, 40)

	local roundActive = false

	local function applyState()
		titleLabel.Text = string.upper(Localization.Get("StartSectionTitle"))

		if roundActive then
			button.Text = Localization.Get("RoundStop")
			button.BackgroundColor3 = STOP_COLOR
			button.TextColor3 = Color3.fromRGB(255, 245, 245)
		else
			button.Text = Localization.Get("RoundStart")
			button.BackgroundColor3 = START_COLOR
			button.TextColor3 = Color3.fromRGB(15, 20, 15)
		end
	end

	button.MouseButton1Click:Connect(function()
		SetRoundActiveEvent:FireServer(not roundActive)
	end)

	RoundChangedEvent.OnClientEvent:Connect(function(active: boolean)
		roundActive = active
		applyState()
	end)

	Localization.OnChanged(applyState)
end

return RoundUI
