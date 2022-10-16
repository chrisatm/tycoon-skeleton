local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
repeat wait() until char:FindFirstChild("Humanoid")
local humanoid = char.Humanoid

local function handleSprint(shouldSprint)
	local configs = ReplicatedStorage:FindFirstChild("Configs")
	if not configs then return end
	local sprintSpeed = configs:FindFirstChild("SprintSpeed")
	if not sprintSpeed then return end
	if shouldSprint == true then
		humanoid.WalkSpeed = sprintSpeed.Value
	else
		humanoid.WalkSpeed = 16
	end
end

local function handleInput(actionName, inputState, inputObject)
	if actionName == "Sprint" then
		local shouldSprint = false
		if inputState == Enum.UserInputState.Begin then
			shouldSprint = true
		end
		handleSprint(shouldSprint)
	end
end

local function listenInputs()
	ContextActionService:BindAction("Sprint", handleInput, true, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonX)
	ContextActionService:SetTitle("Sprint", "Sprint")
end

listenInputs()
