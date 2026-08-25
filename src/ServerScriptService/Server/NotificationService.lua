local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NotifyEvent = ReplicatedStorage.RemoteEvents:WaitForChild("Notify")

local NotificationService = {}

function NotificationService.Toast(player: Player, text: string, color: Color3?)
	NotifyEvent:FireClient(player, "Toast", text, color)
end

function NotificationService.ToastAll(text: string, color: Color3?)
	NotifyEvent:FireAllClients("Toast", text, color)
end

function NotificationService.Feed(text: string)
	NotifyEvent:FireAllClients("Feed", text)
end

return NotificationService
