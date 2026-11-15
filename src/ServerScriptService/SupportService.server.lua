--!strict

-- Optional rewarded video ads (Roblox AdService) and the creator's business numbers.
--
-- A player presses "Watch a video" in Journeys > Support. If Roblox has an ad for them (ads are
-- only offered to eligible players; Roblox decides eligibility by age, region, and device), the
-- server shows it. When it completes, Roblox grants the hidden "ad_reward_tokens" developer
-- product, which ShopService turns into Knowledge Tokens and records in the business ledger.
-- Nothing in the game is locked behind ads.

local Players = game:GetService("Players")
local AdService = game:GetService("AdService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MonetizationConfig = require(Shared.Config.MonetizationConfig)
local PlayerProgress = require(script.Parent.Modules.PlayerProgress)
local BusinessMetrics = require(script.Parent.Modules.BusinessMetrics)
local Analytics = require(script.Parent.Modules.Analytics)

local remotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Support")
local request = remotes:WaitForChild("Request") :: RemoteEvent
local stateEvent = remotes:WaitForChild("State") :: RemoteEvent

local config = MonetizationConfig.RewardedAd
local busy: { [Player]: boolean } = {}
local joinedAt: { [Player]: number } = {}

local function today(): number
    return math.floor(os.time() / 86400)
end

local function adsToday(player: Player): number
    if PlayerProgress.GetStat(player, "AdDay") ~= today() then
        return 0
    end

    return PlayerProgress.GetStat(player, "AdsWatchedToday")
end

local function isCreator(player: Player): boolean
    return game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId
end

local function send(player: Player, extra: { [string]: any })
    extra.AdsConfigured = config.DevProductId > 0
    extra.AdsLeftToday = math.max(0, config.DailyLimit - adsToday(player))
    extra.RewardTokens = config.RewardTokens
    extra.IsCreator = isCreator(player)
    stateEvent:FireClient(player, extra)
end

local function watchAd(player: Player)
    if busy[player] then
        return
    end

    if config.DevProductId <= 0 then
        send(player, { Message = "Rewarded videos are not set up yet. The creator needs to add the ad reward product in Creator Hub." })
        return
    end

    if adsToday(player) >= config.DailyLimit then
        send(player, { Message = "That's all the videos for today. Come back tomorrow!" })
        return
    end

    busy[player] = true

    local okAvail, availability = pcall(function()
        return AdService:GetAdAvailabilityNowAsync(Enum.AdFormat.RewardedVideo)
    end)

    if okAvail and availability and availability.AdAvailabilityResult ~= Enum.AdAvailabilityResult.IsAvailable then
        busy[player] = nil
        send(player, { Message = "No video is available for you right now. Ads are only shown to eligible players." })
        return
    end

    local okShow, result = pcall(function()
        local reward = AdService:CreateAdRewardFromDevProductId(config.DevProductId)
        return AdService:ShowRewardedVideoAdAsync(player, reward, config.PlacementId)
    end)

    busy[player] = nil

    if okShow and result == Enum.ShowAdResult.ShowCompleted then
        local profile = PlayerProgress.Get(player)

        if profile then
            if profile.Stats.AdDay ~= today() then
                profile.Stats.AdDay = today()
                profile.Stats.AdsWatchedToday = 0
            end

            PlayerProgress.IncrementStat(player, "AdsWatchedToday", 1)
        end

        Analytics.Custom(player, "RewardedAdCompleted", 1)
        send(player, { Message = string.format("Thanks for watching! +%d Knowledge Tokens are on the way.", config.RewardTokens) })
    else
        Analytics.Custom(player, "RewardedAdNotCompleted", 1)
        send(player, { Message = if okShow then "The video did not finish, so no reward this time." else "Videos are not available here (they only run in the live game)." })
    end
end

request.OnServerEvent:Connect(function(player: Player, action: any)
    if action == "State" then
        send(player, {})
    elseif action == "WatchAd" then
        watchAd(player)
    elseif action == "Ledger" and isCreator(player) then
        send(player, { Ledger = BusinessMetrics.ReadRecent(14), Costs = MonetizationConfig.MonthlyCostsRobux })
    end
end)

Players.PlayerAdded:Connect(function(player: Player)
    joinedAt[player] = os.clock()
    Analytics.Onboarding(player, 1, "Joined")
end)

for _, player in ipairs(Players:GetPlayers()) do
    joinedAt[player] = os.clock()
end

Players.PlayerRemoving:Connect(function(player: Player)
    local started = joinedAt[player]
    joinedAt[player] = nil
    busy[player] = nil

    if started then
        BusinessMetrics.RecordSessionMinutes((os.clock() - started) / 60)
    end
end)
