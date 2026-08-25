local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.UITheme)

local NotifyEvent = ReplicatedStorage.RemoteEvents:WaitForChild("Notify")

local TOAST_LIFETIME = 3
local FEED_LIFETIME = 5
local FEED_MAX_ENTRIES = 5

local NotificationUI = {}

local player = Players.LocalPlayer

function NotificationUI.Init()
	local playerGui = player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "NotificationGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local toastHolder = Instance.new("Frame")
	toastHolder.Name = "Toasts"
	toastHolder.AnchorPoint = Vector2.new(0.5, 0)
	toastHolder.Position = UDim2.new(0.5, 0, 0, 60)
	toastHolder.Size = UDim2.fromOffset(360, 0)
	toastHolder.AutomaticSize = Enum.AutomaticSize.Y
	toastHolder.BackgroundTransparency = 1
	toastHolder.Parent = screenGui

	local toastLayout = Instance.new("UIListLayout")
	toastLayout.Padding = UDim.new(0, 6)
	toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	toastLayout.Parent = toastHolder

	local feedHolder = Instance.new("Frame")
	feedHolder.Name = "Feed"
	feedHolder.AnchorPoint = Vector2.new(1, 0)
	feedHolder.Position = UDim2.new(1, -16, 0, 16)
	feedHolder.Size = UDim2.fromOffset(260, 0)
	feedHolder.AutomaticSize = Enum.AutomaticSize.Y
	feedHolder.BackgroundTransparency = 1
	feedHolder.Parent = screenGui

	local feedLayout = Instance.new("UIListLayout")
	feedLayout.Padding = UDim.new(0, 4)
	feedLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	feedLayout.Parent = feedHolder

	local function showToast(text: string, color: Color3?)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 34)
		label.BackgroundColor3 = Theme.Background
		label.BackgroundTransparency = 0.1
		label.TextColor3 = color or Theme.Accent
		label.Font = Theme.TitleFont
		label.TextSize = 16
		label.Text = text
		label.Parent = toastHolder

		local corner = Instance.new("UICorner")
		corner.CornerRadius = Theme.CornerRadius
		corner.Parent = label

		task.delay(TOAST_LIFETIME, function()
			local fade =
				TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1, BackgroundTransparency = 1 })
			fade.Completed:Connect(function()
				label:Destroy()
			end)
			fade:Play()
		end)
	end

	local feedEntries = {}

	local function showFeed(text: string)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 22)
		label.BackgroundTransparency = 1
		label.TextColor3 = Theme.Text
		label.TextStrokeTransparency = 0.5
		label.Font = Theme.BodyFont
		label.TextSize = 14
		label.TextXAlignment = Enum.TextXAlignment.Right
		label.Text = text
		label.Parent = feedHolder

		table.insert(feedEntries, label)
		if #feedEntries > FEED_MAX_ENTRIES then
			local oldest = table.remove(feedEntries, 1)
			oldest:Destroy()
		end

		task.delay(FEED_LIFETIME, function()
			if label.Parent then
				local fade = TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1 })
				fade.Completed:Connect(function()
					label:Destroy()
				end)
				fade:Play()
			end
		end)
	end

	NotifyEvent.OnClientEvent:Connect(function(kind: string, text: string, color: Color3?)
		if kind == "Toast" then
			showToast(text, color)
		elseif kind == "Feed" then
			showFeed(text)
		end
	end)
end

return NotificationUI
