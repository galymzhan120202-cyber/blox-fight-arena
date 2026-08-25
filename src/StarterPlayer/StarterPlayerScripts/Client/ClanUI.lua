local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuUI = require(script.Parent.MenuUI)
local Theme = require(script.Parent.UITheme)
local Localization = require(script.Parent.Localization)

local ClanCreateEvent = ReplicatedStorage.RemoteEvents:WaitForChild("ClanCreate")
local ClanJoinEvent = ReplicatedStorage.RemoteEvents:WaitForChild("ClanJoin")
local ClanLeaveEvent = ReplicatedStorage.RemoteEvents:WaitForChild("ClanLeave")
local ClanUpdatedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("ClanUpdated")

local ClanUI = {}

function ClanUI.Init()
	local holder, titleLabel = MenuUI.AddSection(Localization.Get("ClanSectionTitle"), "Дүкен")

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, 0, 0, 0)
	statusLabel.AutomaticSize = Enum.AutomaticSize.Y
	statusLabel.BackgroundTransparency = 1
	statusLabel.Font = Theme.BodyFont
	statusLabel.TextSize = 13
	statusLabel.TextColor3 = Theme.MutedText
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.TextWrapped = true
	statusLabel.Text = Localization.Get("ClanNone")
	statusLabel.Parent = holder

	local nameBox = Instance.new("TextBox")
	nameBox.Size = UDim2.new(1, 0, 0, 30)
	nameBox.BackgroundColor3 = Theme.Idle
	nameBox.TextColor3 = Theme.Text
	nameBox.Font = Theme.BodyFont
	nameBox.TextSize = 14
	nameBox.PlaceholderText = Localization.Get("ClanNamePlaceholder")
	nameBox.ClearTextOnFocus = false
	nameBox.Parent = holder

	local corner = Instance.new("UICorner")
	corner.CornerRadius = Theme.CornerRadius
	corner.Parent = nameBox

	local createButton = MenuUI.CreateButton(holder, Localization.Get("ClanCreate"))
	local joinButton = MenuUI.CreateButton(holder, Localization.Get("ClanJoin"))
	local leaveButton = MenuUI.CreateButton(holder, Localization.Get("ClanLeave"))

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

	local lastPayload = nil

	local function applyStatus()
		if lastPayload and lastPayload.ClanName then
			statusLabel.Text = Localization.Get("ClanStatus", lastPayload.ClanName, lastPayload.MemberCount)
		else
			statusLabel.Text = Localization.Get("ClanNone")
		end
	end

	ClanUpdatedEvent.OnClientEvent:Connect(function(payload)
		lastPayload = payload
		applyStatus()
	end)

	Localization.OnChanged(function()
		titleLabel.Text = string.upper(Localization.Get("ClanSectionTitle"))
		nameBox.PlaceholderText = Localization.Get("ClanNamePlaceholder")
		createButton.Text = Localization.Get("ClanCreate")
		joinButton.Text = Localization.Get("ClanJoin")
		leaveButton.Text = Localization.Get("ClanLeave")
		applyStatus()
	end)
end

return ClanUI
