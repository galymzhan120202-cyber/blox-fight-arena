local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuUI = require(script.Parent.MenuUI)
local Theme = require(script.Parent.UITheme)
local Localization = require(script.Parent.Localization)

local SquadInviteEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SquadInvite")
local SquadRespondEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SquadRespond")
local SquadLeaveEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SquadLeave")
local SquadUpdatedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SquadUpdated")
local SquadInviteReceivedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SquadInviteReceived")

local SquadUI = {}

function SquadUI.Init()
	local holder, titleLabel = MenuUI.AddSection(Localization.Get("SquadSectionTitle"), "Дүкен")

	local membersLabel = Instance.new("TextLabel")
	membersLabel.Size = UDim2.new(1, 0, 0, 0)
	membersLabel.AutomaticSize = Enum.AutomaticSize.Y
	membersLabel.BackgroundTransparency = 1
	membersLabel.Font = Theme.BodyFont
	membersLabel.TextSize = 13
	membersLabel.TextColor3 = Theme.MutedText
	membersLabel.TextXAlignment = Enum.TextXAlignment.Left
	membersLabel.TextWrapped = true
	membersLabel.Text = Localization.Get("SquadSolo")
	membersLabel.Parent = holder

	local nameBox = Instance.new("TextBox")
	nameBox.Size = UDim2.new(1, 0, 0, 30)
	nameBox.BackgroundColor3 = Theme.Idle
	nameBox.TextColor3 = Theme.Text
	nameBox.Font = Theme.BodyFont
	nameBox.TextSize = 14
	nameBox.PlaceholderText = Localization.Get("SquadNamePlaceholder")
	nameBox.ClearTextOnFocus = false
	nameBox.Parent = holder

	local corner = Instance.new("UICorner")
	corner.CornerRadius = Theme.CornerRadius
	corner.Parent = nameBox

	local inviteButton = MenuUI.CreateButton(holder, Localization.Get("SquadInviteButton"))
	local leaveButton = MenuUI.CreateButton(holder, Localization.Get("SquadLeaveButton"))

	local inviteBanner = Instance.new("Frame")
	inviteBanner.AutomaticSize = Enum.AutomaticSize.Y
	inviteBanner.Size = UDim2.fromScale(1, 0)
	inviteBanner.BackgroundTransparency = 1
	inviteBanner.Visible = false
	inviteBanner.Parent = holder

	local inviteBannerLayout = Instance.new("UIListLayout")
	inviteBannerLayout.Padding = UDim.new(0, 4)
	inviteBannerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	inviteBannerLayout.Parent = inviteBanner

	local inviteText = Instance.new("TextLabel")
	inviteText.Size = UDim2.new(1, 0, 0, 0)
	inviteText.AutomaticSize = Enum.AutomaticSize.Y
	inviteText.BackgroundTransparency = 1
	inviteText.Font = Theme.BodyFont
	inviteText.TextSize = 13
	inviteText.TextColor3 = Theme.Accent
	inviteText.TextXAlignment = Enum.TextXAlignment.Left
	inviteText.TextWrapped = true
	inviteText.Text = ""
	inviteText.LayoutOrder = 0
	inviteText.Parent = inviteBanner

	local acceptButton = MenuUI.CreateButton(inviteBanner, Localization.Get("SquadAccept"))
	acceptButton.LayoutOrder = 1
	local declineButton = MenuUI.CreateButton(inviteBanner, Localization.Get("SquadDecline"))
	declineButton.LayoutOrder = 2

	inviteButton.MouseButton1Click:Connect(function()
		if nameBox.Text ~= "" then
			SquadInviteEvent:FireServer(nameBox.Text)
		end
	end)

	leaveButton.MouseButton1Click:Connect(function()
		SquadLeaveEvent:FireServer()
	end)

	acceptButton.MouseButton1Click:Connect(function()
		SquadRespondEvent:FireServer(true)
		inviteBanner.Visible = false
	end)

	declineButton.MouseButton1Click:Connect(function()
		SquadRespondEvent:FireServer(false)
		inviteBanner.Visible = false
	end)

	local lastNames = {}
	local lastInviter = nil

	local function applyMembers()
		if #lastNames == 0 then
			membersLabel.Text = Localization.Get("SquadSolo")
		else
			membersLabel.Text = Localization.Get("SquadMembers", table.concat(lastNames, ", "))
		end
	end

	SquadUpdatedEvent.OnClientEvent:Connect(function(names)
		lastNames = names
		applyMembers()
	end)

	SquadInviteReceivedEvent.OnClientEvent:Connect(function(inviterName: string)
		lastInviter = inviterName
		inviteText.Text = Localization.Get("SquadInvitePrompt", inviterName)
		inviteBanner.Visible = true
	end)

	Localization.OnChanged(function()
		titleLabel.Text = string.upper(Localization.Get("SquadSectionTitle"))
		nameBox.PlaceholderText = Localization.Get("SquadNamePlaceholder")
		inviteButton.Text = Localization.Get("SquadInviteButton")
		leaveButton.Text = Localization.Get("SquadLeaveButton")
		acceptButton.Text = Localization.Get("SquadAccept")
		declineButton.Text = Localization.Get("SquadDecline")
		if lastInviter then
			inviteText.Text = Localization.Get("SquadInvitePrompt", lastInviter)
		end
		applyMembers()
	end)
end

return SquadUI
