--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ContentIndex = require(Shared.Modules.ContentIndex)

local player = Players.LocalPlayer
local content = ContentIndex.GetStartupPayload()

print(string.format(
    "[ClientBootstrap] %s entered %s. Stories: %d, Battles: %d, Travel Stops: %d.",
    player.Name,
    content.Config.HubName,
    #content.Stories,
    #content.Battles,
    #content.TravelRoute.Destinations
))
