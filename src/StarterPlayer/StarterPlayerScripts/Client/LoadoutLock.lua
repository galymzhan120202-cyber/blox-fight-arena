local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.UITheme)
local Localization = require(script.Parent.Localization)

local RoundChangedEvent = ReplicatedStorage.RemoteEvents:WaitForChild("RoundChanged")

local LoadoutLock = {}

-- Класс/Қару таңдау панельдеріне ортақ "раунд барысында құлыпталған" көрінісін
-- қосады: жоғарыда ескерту жолағы, батырмалар сұрланып, басылмай қалады.
function LoadoutLock.Attach(holder: Frame, buttons: { [any]: TextButton })
	local hint = Instance.new("TextLabel")
	hint.Size = UDim2.new(1, 0, 0, 16)
	hint.BackgroundTransparency = 1
	hint.Font = Theme.BodyFont
	hint.TextSize = 12
	hint.TextColor3 = Theme.Warning
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.TextWrapped = true
	hint.Text = ""
	hint.Visible = false
	hint.LayoutOrder = -1
	hint.Parent = holder

	local function applyLocked(locked: boolean)
		hint.Visible = locked
		hint.Text = locked and ("🔒 " .. Localization.Get("LoadoutLockedHint")) or ""

		for _, button in buttons do
			button.Active = not locked
			button.BackgroundTransparency = locked and 0.55 or 0
			button.TextTransparency = locked and 0.5 or 0
		end
	end

	RoundChangedEvent.OnClientEvent:Connect(applyLocked)

	Localization.OnChanged(function()
		if hint.Visible then
			hint.Text = "🔒 " .. Localization.Get("LoadoutLockedHint")
		end
	end)
end

return LoadoutLock
