--!strict

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local function applyBattleCameraMode()
    if player:GetAttribute("InBattle") == true then
        player.CameraMode = Enum.CameraMode.LockFirstPerson

        local camera = Workspace.CurrentCamera

        if camera then
            camera.FieldOfView = 74
        end
    else
        player.CameraMode = Enum.CameraMode.Classic

        local camera = Workspace.CurrentCamera

        if camera and camera.CameraType ~= Enum.CameraType.Scriptable then
            camera.FieldOfView = 70
        end
    end
end

player:GetAttributeChangedSignal("InBattle"):Connect(applyBattleCameraMode)
applyBattleCameraMode()
