local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local DataStore2 = require(ServerScriptService.DataStore2)

local Events = ReplicatedStorage:WaitForChild("Events")
local PromptRequest = Events:WaitForChild("PromptRequest")
local NotificationEvent = Events:WaitForChild("Notification")
local CountdownEvent = Events:WaitForChild("Countdown")

local purchasePlate = script.Parent
local masterModel = purchasePlate.Parent
local modelName = purchasePlate:FindFirstChild("Name") or masterModel.Name
local modelCost = purchasePlate:FindFirstChild("Cost")
local modelPoints = purchasePlate:FindFirstChild("Points")
local modelDuration = purchasePlate:FindFirstChild("Duration")

-- configs
local ACTION_TEXT = "Purchase" .. " for " .. "$" .. modelCost.Value
local GAMEPAD_KEYCODE = Enum.KeyCode.ButtonX
local HOLD_DURATION = 1
local KEYBOARD_KEYCODE = Enum.KeyCode.E
local MAX_ACTIVATION_DISTANCE = 10
local NAME = modelName.Value
local OBJECT_TEXT = modelName.Value
local REQUIRES_LINE_OF_SIGHT = false
local ISA_VALUES = {
	"UnionOperation",
	"Part",
	"Seat",
	"WedgePart",
	"MeshPart"
}

local heartbeatConnection = nil

function setTransparency(value)
	local transparency = value
	-- default values are based on value == 1, which makes parts invis - used to make placer part invis
	local canCollide = false
	local seatDisabled = true
	local windowTransparency = 0.8
	-- value of 0, then make models visible
	if value == 0 then
		canCollide = true
		seatDisabled = false
	end
	local function set(inst)
		if table.find(ISA_VALUES, inst.ClassName) then
			inst.Transparency = transparency
			inst.CanCollide = canCollide
			if inst:IsA("Seat") then
				inst.Disabled = seatDisabled
			end
			if inst.Material == Enum.Material.Glass then
				inst.Transparency = windowTransparency
			end
		end
	end
	for i, child in pairs(masterModel:GetChildren()) do
		if child ~= script.Parent then
			if child:IsA("Model") then
				for i2, modelChild in pairs(child:GetChildren()) do
					set(modelChild)
				end
			else
				set(child)
			end
		end
	end
end

function initializePrompt()
	-- remove physical build parts
	setTransparency(1)
	-- get current level of item
	local stringValue = modelName.Value
	local stringLength = string.len(stringValue)
	local levelCharacter1 = string.sub(stringValue,stringLength-1,stringLength-1)
	local levelCharacter2 = string.sub(stringValue,stringLength,stringLength)
	local level = tonumber(levelCharacter1.. levelCharacter2)
	-- create a level value
	local levelObject = Instance.new("NumberValue")
	levelObject.Name = "Level"
	levelObject.Parent = purchasePlate
	levelObject.Value = level
	-- create set duration value
	local setDurationObject = Instance.new("NumberValue")
	setDurationObject.Name = "SetDuration"
	setDurationObject.Parent = purchasePlate
	setDurationObject.Value = modelDuration.Value
	-- create purchased value
	local purchasedObject = Instance.new("BoolValue")
	purchasedObject.Name = "Purchased"
	purchasedObject.Parent = purchasePlate
	purchasedObject.Value = false
	-- create prompt
	local prompt = Instance.new("ProximityPrompt")
	-- alter prompt properties
	prompt.Name = NAME
	prompt.ActionText = ACTION_TEXT
	prompt.GamepadKeyCode = GAMEPAD_KEYCODE
	prompt.HoldDuration = HOLD_DURATION
	prompt.KeyboardKeyCode = KEYBOARD_KEYCODE
	prompt.MaxActivationDistance = MAX_ACTIVATION_DISTANCE
	prompt.ObjectText = OBJECT_TEXT
	prompt.Parent = purchasePlate
	prompt.RequiresLineOfSight = REQUIRES_LINE_OF_SIGHT
	-- listen to prompt triggered event
	prompt.Triggered:Connect(function(player)
		-- purchase is triggered
		-- check if enough money
		local currencyStore = DataStore2("currency", player)
		--local pointsStore = DataStore2("points", player)
		local playerCurrencyAmount = currencyStore:Get(0) -- The "0" means that by default, they'll have 0 points
		if playerCurrencyAmount > modelCost.Value then
			-- if enough money then charge money and begin timer and setTransparency(0)
			-- disable prompt and plate
			prompt.Enabled = false
			purchasePlate.Transparency = 1
			purchasePlate.CanCollide = false
			local purchasePlateGui = purchasePlate:FindFirstChild("SurfaceGui")
			if purchasePlateGui then
				purchasePlateGui.Enabled = false
			end
			-- subtract money and add points
			currencyStore:Increment(-modelCost.Value)
			--pointsStore:Increment(modelPoints.Value)
			-- send notifcation
			local msg = "You purchased " .. modelName.Value .. " for " .. "$" .. modelCost.Value
			NotificationEvent:FireClient(player,msg)
			-- send player modelDuration object value to listen to
			CountdownEvent:FireClient(player, modelDuration)
			-- after timer is up then make model visible
			local counter = 0
			heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
				counter = counter + dt  --step is time in seconds since the previous frame
				if counter >= setDurationObject.Value then
					purchasedObject.Value = true
					setTransparency(0)
					modelDuration.Value = 0
					heartbeatConnection:Disconnect()
				else
					modelDuration.Value = setDurationObject.Value - counter
				end
			end)
		else
			-- not enough money
			-- disable then enable the prompt again after 1 second
			prompt.Enabled = false
			task.delay(1, function()
				prompt.Enabled = true
			end)
			-- send a notification
			local moneyNeeded = modelCost.Value - playerCurrencyAmount
			local msg = "You need $" .. moneyNeeded .. "more to complete this purchase."
			NotificationEvent:FireClient(player,msg)
		end
	end)
end

-- run script
initializePrompt()
