local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Events = ReplicatedStorage:WaitForChild("Events")
local NotificationEvent = Events:WaitForChild("Notification")
local CountdownEvent = Events:WaitForChild("Countdown")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local assetsUI = Assets:WaitForChild("UI")

local Changelog = require(ReplicatedStorage.Changelog)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local changelogGUI = playerGui:WaitForChild("ChangelogGui")
local mainFrame = changelogGUI:WaitForChild("Frame")
local bodyFrame = mainFrame:WaitForChild("BodyFrame")
local closeFrame = mainFrame:WaitForChild("CloseFrame")
local closeButton = closeFrame:WaitForChild("TextButton")

local notifGui = playerGui:WaitForChild("NotifGui")
local notifQueue = {}
local notifs = {}
local NOTIF_LIMIT = 5

local function setNotifPos()
	local position = UDim2.new(0,0,0,0)
	for i, notif in pairs(notifs) do
		local increment = 0.2
		local newValue = (i - 1) * increment
		notif.Position = position + UDim2.new(0,0,newValue,0)
	end
end

local function createNotif()
	-- get next message from queue
	local message = notifQueue[1]
	table.remove(notifQueue, 1)
	local notifFrameAsset = assetsUI:WaitForChild("NotifFrame")
	local clonedNotifFrame = notifFrameAsset:Clone()
	local textLabel = clonedNotifFrame:WaitForChild("TextLabel")
	textLabel.Text = message
	table.insert(notifs, clonedNotifFrame)
	setNotifPos()
	clonedNotifFrame.Parent = notifGui:WaitForChild("Frame")
	local closeFrame = clonedNotifFrame:WaitForChild("CloseFrame")
	local closeButton = closeFrame:WaitForChild("TextButton")
	local closeConnection = nil
	closeConnection = closeButton.Activated:Connect(function()
		if clonedNotifFrame.Parent == nil then return end
		local notifIndex = table.find(notifs, clonedNotifFrame)
		if notifIndex then
			table.remove(notifs, notifIndex)
		end
		if closeConnection then
			closeConnection:Disconnect()
		end
		clonedNotifFrame:Destroy()
		clonedNotifFrame.Parent = nil
	end)
	task.delay(3, function()
		if clonedNotifFrame.Parent == nil then return end
		local notifIndex = table.find(notifs, clonedNotifFrame)
		if notifIndex then
			table.remove(notifs, notifIndex)
		end
		if closeConnection then
			closeConnection:Disconnect()
		end
		clonedNotifFrame:Destroy()
		clonedNotifFrame.Parent = nil
	end)
end

local function initCountdown()
	CountdownEvent.OnClientEvent:Connect(function(durationObjVal)
		local durationObjectValue = durationObjVal
		local placerPlate = durationObjectValue.Parent
		local setDuration = placerPlate:FindFirstChild("SetDuration")
		local billboard = ReplicatedStorage.Assets.UI.DurationGui:Clone()
		billboard.Parent = placerPlate
		local barFrame = billboard:FindFirstChild("BarFrame")
		local progressBar = barFrame:FindFirstChild("Progress")
		local heartbeatConnection = nil
		heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
			local progressPercentage = 1 - (durationObjectValue.Value/setDuration.Value)
			progressBar.Size = UDim2.new(progressPercentage,0,1,0)
			if progressPercentage >= 1 then
				billboard.Parent = nil
				billboard:Destroy()
				heartbeatConnection:Disconnect()
			end
		end)
	end)
end

local function initNotifications()
	NotificationEvent.OnClientEvent:Connect(function(message)
		table.insert(notifQueue, message)
		-- notifs table has less then 5 values in it then display a message
		if #notifs < NOTIF_LIMIT then
			createNotif()
		end
	end)
end

local function initChangelog()
	changelogGUI.Enabled = true
	for i, changeLine in pairs(Changelog.Logs) do
		local textLabel = Instance.new("TextLabel")
		textLabel.Size = UDim2.new(1,0,0.05,0)
		textLabel.TextSize = 12
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		textLabel.BackgroundTransparency = 1
		textLabel.Text = changeLine
		textLabel.Parent = bodyFrame
	end
	closeButton.Activated:Connect(function()
		changelogGUI.Enabled = false
	end)
end

initChangelog()
initNotifications()
initCountdown()
