--!strict

-- Playing with friends. Roblox already lets friends join each other's server from the app;
-- in game, players can invite friends (SocialService invite prompt, on the client), see which
-- friends are here, and jump to a friend to play the same activity. Muting chat, blocking, and
-- reporting use Roblox's own tools on the client (see SocialPanel in JourneyBook).
--
-- Voice chat is Roblox's platform voice: it works only for eligible players (age-verified 13+
-- with voice enabled) and only after the experience enables it in Creator Hub. This script only
-- reports who in the server can use it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local VoiceChatService = game:GetService("VoiceChatService")

local remotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Social")
local request = remotes:WaitForChild("Request") :: RemoteEvent
local stateEvent = remotes:WaitForChild("State") :: RemoteEvent

local lastJump: { [Player]: number } = {}
-- mutedBy[sender][recipient] = true: the recipient chose not to see or hear the sender.
local mutedBy: { [number]: { [number]: boolean } } = {}

-- Chat mute: messages from a muted player are not delivered to the player who muted them.
local function hookChannel(channel: Instance)
    if not channel:IsA("TextChannel") then
        return
    end

    channel.ShouldDeliverCallback = function(message: TextChatMessage, recipient: TextSource)
        local sender = message.TextSource
        local muted = sender and mutedBy[sender.UserId]

        return not (muted and muted[recipient.UserId])
    end
end

task.spawn(function()
    local channels = TextChatService:WaitForChild("TextChannels", 30)

    if channels then
        for _, channel in ipairs(channels:GetChildren()) do
            hookChannel(channel)
        end

        channels.ChildAdded:Connect(hookChannel)
    end
end)

-- Voice mute: with Roblox's audio API, each speaker's microphone (AudioDeviceInput) can deny
-- listeners. Roblox's own player-list mute also works and needs nothing from the game.
local function applyVoiceMute(sender: Player)
    local input = sender:FindFirstChildOfClass("AudioDeviceInput")
    local muted = mutedBy[sender.UserId]

    if not input then
        return false
    end

    local list = {}

    for userId in pairs(muted or {}) do
        table.insert(list, userId)
    end

    local ok = pcall(function()
        input.AccessType = Enum.AccessModifierType.Deny;
        (input :: any):SetUserIdAccessList(list)
    end)

    return ok
end

local function setMute(player: Player, targetUserId: any, muted: any)
    local target = type(targetUserId) == "number" and Players:GetPlayerByUserId(targetUserId)

    if not target or target == player then
        return
    end

    local list = mutedBy[target.UserId] or {}
    mutedBy[target.UserId] = list
    list[player.UserId] = if muted == true then true else nil
    local voiceApplied = applyVoiceMute(target)

    stateEvent:FireClient(player, {
        Muted = { UserId = target.UserId, Muted = muted == true },
        Message = if muted == true
            then string.format("%s is muted for you (chat%s).", target.DisplayName, if voiceApplied then " and voice" else "")
            else string.format("%s is unmuted.", target.DisplayName),
    })
end
local voiceCache: { [number]: boolean } = {}

local function voiceEnabled(userId: number): boolean
    if voiceCache[userId] == nil then
        local ok, result = pcall(function()
            return VoiceChatService:IsVoiceEnabledForUserIdAsync(userId)
        end)
        voiceCache[userId] = ok and result == true
    end

    return voiceCache[userId]
end

local function busy(player: Player): boolean
    return player:GetAttribute("InBattle") == true or player:GetAttribute("InStory") == true
end

local function jumpTo(player: Player, targetUserId: any)
    if type(targetUserId) ~= "number" then
        return
    end

    local target = Players:GetPlayerByUserId(targetUserId)
    local now = os.clock()

    if not target or target == player or busy(player) then
        return
    end

    if lastJump[player] and now - lastJump[player] < 5 then
        return
    end

    -- Only friends can be joined directly, so nobody can follow a stranger around.
    local ok, isFriend = pcall(function()
        return player:IsFriendsWith(target.UserId)
    end)

    if not ok or not isFriend then
        stateEvent:FireClient(player, { Message = "You can only jump to players on your friends list." })
        return
    end

    if busy(target) then
        stateEvent:FireClient(player, { Message = string.format("%s is in a battle or story right now. Try again soon.", target.DisplayName) })
        return
    end

    local character = player.Character
    local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")

    if character and targetRoot and targetRoot:IsA("BasePart") then
        lastJump[player] = now
        character:PivotTo(targetRoot.CFrame * CFrame.new(3, 0, 3))
        stateEvent:FireClient(player, { Message = string.format("You joined %s.", target.DisplayName) })
        stateEvent:FireClient(target, { Message = string.format("%s joined you.", player.DisplayName) })
    end
end

request.OnServerEvent:Connect(function(player: Player, action: any, argument: any)
    if action == "JumpTo" then
        jumpTo(player, argument)
    elseif action == "Mute" and type(argument) == "table" then
        setMute(player, argument.UserId, argument.Muted)
    elseif action == "Voice" then
        local list = {}

        for _, other in ipairs(Players:GetPlayers()) do
            list[tostring(other.UserId)] = voiceEnabled(other.UserId)
        end

        stateEvent:FireClient(player, { Voice = list })
    end
end)

Players.PlayerAdded:Connect(function(player: Player)
    -- Tell friends already here that someone they know arrived.
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player then
            task.spawn(function()
                local ok, isFriend = pcall(function()
                    return other:IsFriendsWith(player.UserId)
                end)

                if ok and isFriend then
                    stateEvent:FireClient(other, { Message = string.format("Your friend %s joined the server.", player.DisplayName) })
                end
            end)
        end
    end
end)

Players.PlayerRemoving:Connect(function(player: Player)
    lastJump[player] = nil
    mutedBy[player.UserId] = nil

    for _, list in pairs(mutedBy) do
        list[player.UserId] = nil
    end

    voiceCache[player.UserId] = nil
end)
