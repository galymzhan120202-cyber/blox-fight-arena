local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuUI = require(script.Parent.MenuUI)
local Theme = require(script.Parent.UITheme)
local Localization = require(script.Parent.Localization)
local RankTiers = require(ReplicatedStorage.Modules.Data.RankTiers)

local RequestLeaderboardEvent = ReplicatedStorage.RemoteEvents:WaitForChild("RequestLeaderboard")
local LeaderboardDataEvent = ReplicatedStorage.RemoteEvents:WaitForChild("LeaderboardData")

local LeaderboardUI = {}

function LeaderboardUI.Init()
	local holder, titleLabel = MenuUI.AddSection(Localization.Get("LeaderboardTitle"), "Дүкен")

	local youLabel = Instance.new("TextLabel")
	youLabel.Size = UDim2.new(1, 0, 0, 0)
	youLabel.AutomaticSize = Enum.AutomaticSize.Y
	youLabel.BackgroundTransparency = 1
	youLabel.Font = Theme.TitleFont
	youLabel.TextSize = 13
	youLabel.TextColor3 = Theme.Accent
	youLabel.TextXAlignment = Enum.TextXAlignment.Left
	youLabel.TextWrapped = true
	youLabel.Text = "—"
	youLabel.LayoutOrder = -1
	youLabel.Parent = holder

	local refreshButton = MenuUI.CreateButton(holder, Localization.Get("LeaderboardRefresh"))
	refreshButton.LayoutOrder = 0

	local listLabel = Instance.new("TextLabel")
	listLabel.Size = UDim2.new(1, 0, 0, 0)
	listLabel.AutomaticSize = Enum.AutomaticSize.Y
	listLabel.BackgroundTransparency = 1
	listLabel.Font = Theme.BodyFont
	listLabel.TextSize = 13
	listLabel.TextColor3 = Theme.Text
	listLabel.TextXAlignment = Enum.TextXAlignment.Left
	listLabel.TextYAlignment = Enum.TextYAlignment.Top
	listLabel.TextWrapped = true
	listLabel.LayoutOrder = 1
	listLabel.Text = Localization.Get("LeaderboardLoading")
	listLabel.Parent = holder

	local lastPayload = nil

	local function render()
		if not lastPayload then
			return
		end

		youLabel.Text = Localization.Get("LeaderboardYou", lastPayload.You.Tier, lastPayload.You.RankPoints)

		local entries = lastPayload.Top
		if #entries == 0 then
			listLabel.Text = Localization.Get("LeaderboardEmpty")
			return
		end

		local lines = {}
		for index, entry in entries do
			table.insert(
				lines,
				Localization.Get("LeaderboardEntry", index, entry.Name, RankTiers.GetTier(entry.RankPoints), entry.RankPoints)
			)
		end
		listLabel.Text = table.concat(lines, "\n")
	end

	refreshButton.MouseButton1Click:Connect(function()
		listLabel.Text = Localization.Get("LeaderboardLoading")
		RequestLeaderboardEvent:FireServer()
	end)

	LeaderboardDataEvent.OnClientEvent:Connect(function(payload)
		lastPayload = payload
		render()
	end)

	RequestLeaderboardEvent:FireServer()

	Localization.OnChanged(function()
		titleLabel.Text = string.upper(Localization.Get("LeaderboardTitle"))
		refreshButton.Text = Localization.Get("LeaderboardRefresh")
		if lastPayload then
			render()
		else
			listLabel.Text = Localization.Get("LeaderboardLoading")
		end
	end)
end

return LeaderboardUI
