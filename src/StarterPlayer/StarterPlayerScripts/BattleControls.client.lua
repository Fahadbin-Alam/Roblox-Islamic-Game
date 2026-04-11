--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local battleFolder = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Battle")
local requestBlock = battleFolder:WaitForChild("RequestBlock") :: RemoteEvent

local player = Players.LocalPlayer
local localCooldown = false

local function requestSwordBlock()
    if localCooldown or player:GetAttribute("InBattle") ~= true then
        return
    end

    local character = player.Character
    local equippedTool = character and character:FindFirstChildOfClass("Tool")

    if not equippedTool or equippedTool.Name ~= "Training Sword" then
        return
    end

    localCooldown = true
    requestBlock:FireServer()

    task.delay(0.35, function()
        localCooldown = false
    end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        requestSwordBlock()
    end
end)
