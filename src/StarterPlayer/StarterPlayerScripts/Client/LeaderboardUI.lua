local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuUI = require(script.Parent.MenuUI)
local Theme = require(script.Parent.UITheme)

local RequestLeaderboardEvent = ReplicatedStorage.RemoteEvents:WaitForChild("RequestLeaderboard")
local LeaderboardDataEvent = ReplicatedStorage.RemoteEvents:WaitForChild("LeaderboardData")

local LeaderboardUI = {}

function LeaderboardUI.Init()
	local holder = MenuUI.AddSection("Рейтинг", "Дүкен")

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

	LeaderboardDataEvent.OnClientEvent:Connect(function(entries)
		if #entries == 0 then
			listLabel.Text = "Деректер жоқ."
			return
		end

		local lines = {}
		for index, entry in entries do
			table.insert(lines, string.format("%d. %s — %d RP", index, entry.Name, entry.RankPoints))
		end
		listLabel.Text = table.concat(lines, "\n")
	end)

	RequestLeaderboardEvent:FireServer()
end

return LeaderboardUI
