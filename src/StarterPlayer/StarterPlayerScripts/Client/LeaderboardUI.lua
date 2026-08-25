local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuUI = require(script.Parent.MenuUI)
local Theme = require(script.Parent.UITheme)
local RankTiers = require(ReplicatedStorage.Modules.Data.RankTiers)

local RequestLeaderboardEvent = ReplicatedStorage.RemoteEvents:WaitForChild("RequestLeaderboard")
local LeaderboardDataEvent = ReplicatedStorage.RemoteEvents:WaitForChild("LeaderboardData")

local LeaderboardUI = {}

function LeaderboardUI.Init()
	local holder = MenuUI.AddSection("Рейтинг", "Дүкен")

	local youLabel = Instance.new("TextLabel")
	youLabel.Size = UDim2.new(1, 0, 0, 18)
	youLabel.BackgroundTransparency = 1
	youLabel.Font = Theme.TitleFont
	youLabel.TextSize = 13
	youLabel.TextColor3 = Theme.Accent
	youLabel.TextXAlignment = Enum.TextXAlignment.Left
	youLabel.Text = "Сіздің дәрежеңіз: —"
	youLabel.LayoutOrder = -1
	youLabel.Parent = holder

	local refreshButton = MenuUI.CreateButton(holder, "Жаңарту")

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
	listLabel.Text = "Жүктелуде..."
	listLabel.Parent = holder

	refreshButton.MouseButton1Click:Connect(function()
		listLabel.Text = "Жүктелуде..."
		RequestLeaderboardEvent:FireServer()
	end)

	LeaderboardDataEvent.OnClientEvent:Connect(function(payload)
		youLabel.Text = string.format("Сіздің дәрежеңіз: %s (%d RP)", payload.You.Tier, payload.You.RankPoints)

		local entries = payload.Top
		if #entries == 0 then
			listLabel.Text = "Деректер жоқ."
			return
		end

		local lines = {}
		for index, entry in entries do
			table.insert(
				lines,
				string.format("%d. %s — %s (%d RP)", index, entry.Name, RankTiers.GetTier(entry.RankPoints), entry.RankPoints)
			)
		end
		listLabel.Text = table.concat(lines, "\n")
	end)

	RequestLeaderboardEvent:FireServer()
end

return LeaderboardUI
