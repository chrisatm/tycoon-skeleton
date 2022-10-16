local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStore2 = require(script.Parent.DataStore2)
-- Always "combine" any key you use! To understand why, read the "Gotchas" page.
DataStore2.Combine("DATA", "currency")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local Scripts = Assets:WaitForChild("Scripts")
local PromptScript = Scripts:FindFirstChild("PromptScript")

local Configs = ReplicatedStorage:WaitForChild("Configs")

local heartbeatConns = {}

local function timedMoneyGain(plr)
	local configs = ReplicatedStorage:FindFirstChild("Configs")
	if not configs then return end
	local timedMoneyInterval = configs:FindFirstChild("TimedMoneyInterval")
	local timedMoneyAmount = configs:FindFirstChild("TimedMoneyAmount")
	local counter = 0
	local playerHeartbeatConn = RunService.Heartbeat:Connect(function(dt)
		counter = counter + dt  --step is time in seconds since the previous frame
		if counter >= timedMoneyInterval.Value then
			counter = counter - timedMoneyInterval.Value
			local currencyStore = DataStore2("currency", plr)
			currencyStore:Increment(timedMoneyAmount.Value)
		end
	end)
	local playerId = plr.UserId
	heartbeatConns[playerId] = playerHeartbeatConn
end

local function handlePlayerData(plr)
	-- calc level function
	local function calcLevel(pts)
		local levelValue = 0
		local expNeeded = 0
		local pointsParam = pts
		local Configs = ReplicatedStorage:WaitForChild("Configs")
		local LEVEL_FACTOR = Configs:WaitForChild("LevelFactor").Value or 1.5
		local BASE_EXP = Configs:WaitForChild("BaseExp").Value or 10
		repeat
			levelValue += 1
			-- calc how much exp needed to gain next level
			expNeeded = math.floor(BASE_EXP * (levelValue ^ LEVEL_FACTOR))
		until expNeeded > pts
		print("currentLevel:", levelValue)
		print("points needed for next level:", expNeeded)
		return levelValue
	end
	-- add stats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = plr
	-- create currency
	local currencyStore = DataStore2("currency", plr)
	local currency = Instance.new("NumberValue")
	currency.Name = "Money"
	currency.Value = currencyStore:Get(0) -- The "0" means that by default, they'll have 0 points
	currency.Parent = leaderstats
	currencyStore:OnUpdate(function(moneyValue)
		-- This function runs every time the value inside the data store changes.
		currency.Value = moneyValue
	end)
	
	--[[ LEVEL STUFF (Feature Removed) ]]
	--[[
		-- create level stat -- does not get saved to Datastore
		local level = Instance.new("NumberValue")
		level.Name = "Level"
		level.Parent = leaderstats
		-- create points
		local pointsStore = DataStore2("points", plr)
		local points = Instance.new("NumberValue")
		points.Name = "Points"
		points.Value = pointsStore:Get(0) -- The "0" means that by default, they'll have 0 points
		level.Value = calcLevel(points.Value)
		points.Parent = leaderstats
		pointsStore:OnUpdate(function(pointsValue)
			-- This function runs every time the value inside the data store changes.
			points.Value = pointsValue
			level.Value = calcLevel(pointsValue)
		end)
	]]

	-- start timedMoneyGain
	timedMoneyGain(plr)
end

Players.PlayerAdded:Connect(function(player)
	-- on character added stuff
	player.CharacterAdded:Connect(function(character)
		
	end)
	-- handle player data
	handlePlayerData(player)
end)

Players.PlayerRemoving:Connect(function(player)
	print(player.Name .. " left the game!")
	-- end player heartbeat connection that gives them money
	local playerConn = heartbeatConns[player.UserId]
	if not playerConn then return end
	playerConn:Disconnect()
end)

local function InitiatePrompts()
	local buildsFolder = game.Workspace:FindFirstChild("BuildsFolder")
	if not buildsFolder then return end
	for i, child in pairs(buildsFolder:GetDescendants()) do
		local addPrompt = child:FindFirstChild("Prompt")
		if addPrompt then
			if addPrompt.Value == true then
				if PromptScript then
					local clonedPromptScript = PromptScript:Clone()
					clonedPromptScript.Parent = child
				end
			end
		end
	end
end

InitiatePrompts()
