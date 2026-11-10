--!strict

-- Server-side owner of every player's saved learning progress (XP, completions, badges, stats).
-- Any server script records progress through this module, e.g.
--     PlayerProgress.RecordCompletion(player, "story", story.Id, story.DisplayName)
-- The module saves to a DataStore, mirrors level info onto player attributes, and pushes a
-- snapshot plus a toast to the client whenever something changes.

local BadgeService = game:GetService("BadgeService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Daily = require(Shared.Modules.Daily)
local Progression = require(Shared.Modules.Progression)
local ShopCatalog = require(Shared.Data.ShopCatalog)

type Profile = Progression.Profile

local STORE_NAME = "PlayerProgress_v1"
local LOAD_ATTEMPTS = 3

local progressFolder = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Progress")
local profileUpdated = progressFolder:WaitForChild("ProfileUpdated") :: RemoteEvent
local progressToast = progressFolder:WaitForChild("ProgressToast") :: RemoteEvent

local store: DataStore? = nil
local storeOk, storeResult = pcall(function()
    return DataStoreService:GetDataStore(STORE_NAME)
end)

if storeOk then
    store = storeResult
else
    warn(string.format("[PlayerProgress] DataStore unavailable, progress will not save: %s", tostring(storeResult)))
end

local profiles: { [Player]: Profile } = {}
-- Profiles that failed to load. They still work for this session but are never saved,
-- so a DataStore outage cannot overwrite a player's real progress with a blank profile.
local unsaveable: { [Player]: boolean } = {}
local dirty: { [Player]: boolean } = {}

local PlayerProgress = {}

local function keyFor(userId: number): string
    return string.format("player_%d", userId)
end

local function setLeaderstat(player: Player, name: string, value: number)
    local leaderstats = player:FindFirstChild("leaderstats")

    if not leaderstats then
        local folder = Instance.new("Folder")
        folder.Name = "leaderstats"
        folder.Parent = player
        leaderstats = folder
    end

    local stat = (leaderstats :: Instance):FindFirstChild(name)

    if not stat or not stat:IsA("IntValue") then
        local intValue = Instance.new("IntValue")
        intValue.Name = name
        intValue.Parent = leaderstats
        stat = intValue
    end

    (stat :: IntValue).Value = value
end

local function applyAttributes(player: Player, profile: Profile)
    local levelInfo = Progression.GetLevelInfo(profile.XP)
    -- Shows each player's level and XP in the Roblox player list.
    setLeaderstat(player, "Level", levelInfo.Level)
    setLeaderstat(player, "XP", profile.XP)
    player:SetAttribute("Level", levelInfo.Level)
    player:SetAttribute("XP", profile.XP)
    player:SetAttribute("RankTitle", Progression.GetRankTitle(levelInfo.Level))
end

local function toast(player: Player, kind: string, title: string, body: string?)
    progressToast:FireClient(player, {
        Kind = kind,
        Title = title,
        Body = body or "",
    })
end

function PlayerProgress.SendSnapshot(player: Player)
    local profile = profiles[player]

    if profile then
        local snapshot: any = Progression.BuildSnapshot(profile)
        snapshot.Daily = Daily.BuildPayload(profile.Stats, Daily.DayNumber(os.time()))
        profileUpdated:FireClient(player, snapshot)
    end
end

local function awardNewBadges(player: Player, profile: Profile)
    for _, badge in ipairs(Progression.FindNewBadges(profile)) do
        profile.Badges[badge.Id] = os.time()
        toast(player, "badge", string.format("Badge earned: %s", badge.DisplayName), badge.Description)

        if badge.RobloxBadgeId > 0 then
            task.spawn(function()
                local ok, err = pcall(function()
                    BadgeService:AwardBadgeAsync(player.UserId, badge.RobloxBadgeId)
                end)

                if not ok then
                    warn(string.format("[PlayerProgress] Could not award Roblox badge %s: %s", badge.Id, tostring(err)))
                end
            end)
        end
    end
end

local function awardCompletedQuests(player: Player, profile: Profile)
    local rewarded = profile.Completed[Progression.Categories.Path]

    if not rewarded then
        rewarded = {}
        profile.Completed[Progression.Categories.Path] = rewarded
    end

    for _, step in ipairs(Progression.FindNewlyCompletedSteps(profile)) do
        -- Mark first: AddXP calls back into changed(), which must not reward the step again.
        rewarded[step.Id] = true
        PlayerProgress.AddXP(player, Progression.GetCompletionReward(Progression.Categories.Path, true), string.format("Quest complete: %s", step.Title))
    end
end

local function changed(player: Player, profile: Profile)
    dirty[player] = true
    awardCompletedQuests(player, profile)
    awardNewBadges(player, profile)
    applyAttributes(player, profile)
    PlayerProgress.SendSnapshot(player)
end

function PlayerProgress.Get(player: Player): Profile?
    return profiles[player]
end

function PlayerProgress.IsLoaded(player: Player): boolean
    return profiles[player] ~= nil
end

-- True when the profile loaded from the DataStore and will be saved, so its numbers are real.
function PlayerProgress.IsSaveable(player: Player): boolean
    return profiles[player] ~= nil and store ~= nil and not unsaveable[player]
end

function PlayerProgress.HasCompleted(player: Player, category: string, id: string): boolean
    local profile = profiles[player]
    local entries = profile and profile.Completed[category]

    return entries ~= nil and entries[id] == true
end

-- Adds XP without recording a completion. Returns the XP actually added.
function PlayerProgress.AddXP(player: Player, amount: number, reason: string?): number
    local profile = profiles[player]
    amount = math.floor(amount)

    if not profile or amount <= 0 then
        return 0
    end

    local levelBefore = Progression.GetLevelInfo(profile.XP).Level
    profile.XP += amount
    local levelAfter = Progression.GetLevelInfo(profile.XP).Level

    if reason then
        toast(player, "xp", string.format("+%d XP", amount), reason)
    end

    if levelAfter > levelBefore then
        toast(player, "level", string.format("Level %d reached!", levelAfter), Progression.GetRankTitle(levelAfter))

        for _, skin in pairs(ShopCatalog.SkinDefinitions) do
            local unlockLevel = (skin :: any).UnlockLevel

            if skin.UnlockType == "Level" and type(unlockLevel) == "number" and unlockLevel > levelBefore and unlockLevel <= levelAfter then
                toast(player, "badge", string.format("Outfit unlocked: %s", skin.DisplayName), "Equip it from the Shop for your next battle.")
            end
        end
    end

    changed(player, profile)

    return amount
end

-- Records that the player finished something and awards XP for it. The first completion
-- earns the full reward and repeats earn a smaller share. Returns true the first time.
function PlayerProgress.RecordCompletion(player: Player, category: string, id: string, displayName: string?): boolean
    local profile = profiles[player]

    if not profile then
        return false
    end

    local entries = profile.Completed[category]

    if not entries then
        entries = {}
        profile.Completed[category] = entries
    end

    local firstTime = entries[id] ~= true
    entries[id] = true

    local reward = Progression.GetCompletionReward(category, firstTime)
    local label = displayName or id

    if reward > 0 then
        PlayerProgress.AddXP(player, reward, if firstTime then string.format("Completed %s", label) else string.format("Replayed %s", label))
    else
        changed(player, profile)
    end

    return firstTime
end

function PlayerProgress.IncrementStat(player: Player, stat: string, amount: number?)
    local profile = profiles[player]

    if not profile then
        return
    end

    profile.Stats[stat] = (profile.Stats[stat] or 0) + (amount or 1)
    changed(player, profile)
end

-- Counts today's visit toward the streak and pays the visit reward the first time each day.
-- Players who stay in a server past midnight UTC get it when ProgressionService checks again.
-- Raises a stat to `value` if it is higher than what is saved (best scores). Returns the
-- previous value, or nil when the profile is not loaded.
function PlayerProgress.SetStatMax(player: Player, stat: string, value: number): number?
    local profile = profiles[player]

    if not profile then
        return nil
    end

    local previous = profile.Stats[stat] or 0

    if value > previous then
        profile.Stats[stat] = value
        changed(player, profile)
    end

    return previous
end

function PlayerProgress.GetStat(player: Player, stat: string): number
    local profile = profiles[player]

    return profile and profile.Stats[stat] or 0
end

function PlayerProgress.RecordDailyVisit(player: Player)
    local profile = profiles[player]

    if not profile then
        return
    end

    local streak, firstVisitToday = Daily.RecordVisit(profile.Stats, Daily.DayNumber(os.time()))

    if not firstVisitToday then
        return
    end

    local label = if streak > 1 then string.format("Daily visit: %d day streak", streak) else "Daily visit"
    PlayerProgress.AddXP(player, Daily.VisitReward(streak), label)
end

-- Grades today's review question. Returns nil when it was already answered today.
function PlayerProgress.AnswerDailyQuestion(player: Player, answerIndex: number): { Correct: boolean, CorrectIndex: number, Explanation: string, XPAwarded: number }?
    local profile = profiles[player]
    local day = Daily.DayNumber(os.time())

    if not profile or Daily.HasAnsweredQuestion(profile.Stats, day) then
        return nil
    end

    local entry = Daily.GetQuestion(day)
    local correct = answerIndex == entry.Question.CorrectIndex
    profile.Stats.DailyQuestionDay = day
    local awarded = 0

    if correct then
        profile.Stats.DailyQuestionsCorrect = (profile.Stats.DailyQuestionsCorrect or 0) + 1
        awarded = PlayerProgress.AddXP(player, Daily.Rewards.Question, "Daily question")
    else
        changed(player, profile)
    end

    return {
        Correct = correct,
        CorrectIndex = entry.Question.CorrectIndex,
        Explanation = entry.Question.Explanation,
        XPAwarded = awarded,
    }
end

function PlayerProgress.Load(player: Player)
    local raw = nil
    local loaded = store == nil

    if store then
        for attempt = 1, LOAD_ATTEMPTS do
            local ok, result = pcall(function()
                return (store :: DataStore):GetAsync(keyFor(player.UserId))
            end)

            if ok then
                raw = result
                loaded = true
                break
            end

            warn(string.format("[PlayerProgress] Load attempt %d failed for %s: %s", attempt, player.Name, tostring(result)))
            task.wait(attempt)
        end
    end

    if not player.Parent then
        return
    end

    local profile = Progression.Sanitize(raw)
    profiles[player] = profile
    if not loaded or store == nil then
        unsaveable[player] = true
    end

    if not loaded then
        toast(player, "warning", "Progress could not load", "You can keep playing, but progress from this visit will not be saved.")
    end

    -- Badges added in an update are granted to players who already qualify.
    awardNewBadges(player, profile)
    applyAttributes(player, profile)
    PlayerProgress.RecordDailyVisit(player)
    PlayerProgress.SendSnapshot(player)
end

function PlayerProgress.Save(player: Player)
    local profile = profiles[player]

    if not profile or not store or unsaveable[player] or not dirty[player] then
        return
    end

    dirty[player] = nil
    local snapshot = table.clone(profile)
    local ok, err = pcall(function()
        (store :: DataStore):SetAsync(keyFor(player.UserId), snapshot, { player.UserId })
    end)

    if not ok then
        dirty[player] = true
        warn(string.format("[PlayerProgress] Save failed for %s: %s", player.Name, tostring(err)))
    end
end

function PlayerProgress.Release(player: Player)
    PlayerProgress.Save(player)
    profiles[player] = nil
    unsaveable[player] = nil
    dirty[player] = nil
end

function PlayerProgress.SaveAll()
    local pending = 0

    for player in pairs(profiles) do
        pending += 1
        task.spawn(function()
            PlayerProgress.Save(player)
            pending -= 1
        end)
    end

    local deadline = os.clock() + 20

    while pending > 0 and os.clock() < deadline do
        task.wait(0.1)
    end
end

return PlayerProgress
