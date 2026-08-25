local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuUI = require(script.Parent.MenuUI)
local Theme = require(script.Parent.UITheme)

local ClanCreateEvent = ReplicatedStorage.RemoteEvents:WaitForChild("ClanCreate")
local ClanJoinEvent = ReplicatedStorage.RemoteEvents:WaitForChild("ClanJoin")
local ClanLeaveEvent = ReplicatedStorage.RemoteEvents:WaitForChild("ClanLeave")
local ClanUpdatedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("ClanUpdated")

local ClanUI = {}

function ClanUI.Init()
	local holder = MenuUI.AddSection("Клан", "Дүкен")

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, 0, 0, 18)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Font = Theme.BodyFont
	statusLabel.TextSize = 13
	statusLabel.TextColor3 = Theme.MutedText
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Text = "Клан: жоқ"
	statusLabel.Parent = holder

	local nameBox = Instance.new("TextBox")
	nameBox.Size = UDim2.new(1, 0, 0, 30)
	nameBox.BackgroundColor3 = Theme.Idle
	nameBox.TextColor3 = Theme.Text
	nameBox.Font = Theme.BodyFont
	nameBox.TextSize = 14
	nameBox.PlaceholderText = "Клан атауы..."
	nameBox.ClearTextOnFocus = false
	nameBox.Parent = holder

	local corner = Instance.new("UICorner")
	corner.CornerRadius = Theme.CornerRadius
	corner.Parent = nameBox

	local createButton = MenuUI.CreateButton(holder, "Клан құру")
	local joinButton = MenuUI.CreateButton(holder, "Кланға қосылу")
	local leaveButton = MenuUI.CreateButton(holder, "Кланнан шығу")

	createButton.MouseButton1Click:Connect(function()
		if nameBox.Text ~= "" then
			ClanCreateEvent:FireServer(nameBox.Text)
		end
	end)

	joinButton.MouseButton1Click:Connect(function()
		if nameBox.Text ~= "" then
			ClanJoinEvent:FireServer(nameBox.Text)
		end
	end)

	leaveButton.MouseButton1Click:Connect(function()
		ClanLeaveEvent:FireServer()
	end)

	ClanUpdatedEvent.OnClientEvent:Connect(function(payload)
		if payload.ClanName then
			statusLabel.Text = string.format("Клан: %s (%d мүше)", payload.ClanName, payload.MemberCount)
		else
			statusLabel.Text = "Клан: жоқ"
		end
	end)
end

return ClanUI
