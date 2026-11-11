--!strict

-- Server-side owner of every player's saved learning progress (XP, completions, badges, stats).
-- Any server script records progress through this module, e.g.
--     PlayerProgress.RecordCompletion(player, "story", story.Id, story.DisplayName)
-- The module saves to a DataStore, mirrors level info onto player attributes, and pushes a
-- snapshot plus a toast to the client whenever something changes.
--
-- Saving goes through SessionStore: the player's key is session-locked while they are in
-- this server, every read and write uses UpdateAsync with retries, and a server that lost
-- the lock (the player is now in another server) stops saving instead of overwriting.

local BadgeService = game:GetService("BadgeService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Daily = require(Shared.Modules.Daily)
local Progression = require(Shared.Modules.Progression)
local ShopCatalog = require(Shared.Data.ShopCatalog)
local SessionStore = require(script.Parent.SessionStore)

type Profile = Progression.Profile

local STORE_NAME = "PlayerProgress_v1"
-- Autosave refreshes the session lock at least this often, even with nothing new to save,
-- so a long quiet visit never looks like a crashed server to the next one.
local LOCK_REFRESH_SECONDS = 10 * 60
-- A repeat of the same lesson, puzzle, story or battle pays its replay XP at most once per
-- this many seconds, so resubmitting a known answer in a loop cannot farm XP.
local REPEAT_REWARD_COOLDOWN_SECONDS = 120
-- BindToClose gets 30 seconds in total; leave a margin.
local SHUTDOWN_SAVE_SECONDS = 25

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

local sessionStore = if store
    then SessionStore.new(store :: any, {
        JobId = game.JobId,
        Now = os.time,
        Wait = function(seconds: number)
            task.wait(seconds)
        end,
        NewId = function()
            return HttpService:GenerateGUID(false)
        end,
        Log = function(message: string)
            warn("[PlayerProgress] " .. message)
        end,
    })
    else nil

local profiles: { [Player]: Profile } = {}
-- The open DataStore session per player. A player without one (the load failed) still
-- plays with a working profile, but it is never saved, so a DataStore outage cannot
-- overwrite their real progress with a blank profile.
local sessions: { [Player]: any } = {}
local dirty: { [Player]: boolean } = {}
local repeatRewardAt: { [Player]: { [string]: number } } = {}
-- Final saves still in flight, so BindToClose can wait for them.
local closingCount = 0

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
    local session = sessions[player]

    return profiles[player] ~= nil and session ~= nil and not session.Lost
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
-- earns the full reward and repeats earn a smaller share (at most once per
-- REPEAT_REWARD_COOLDOWN_SECONDS for the same activity). Returns true the first time, and
-- the XP actually awarded.
function PlayerProgress.RecordCompletion(player: Player, category: string, id: string, displayName: string?): (boolean, number)
    local profile = profiles[player]

    if not profile then
        return false, 0
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

    if not firstTime and reward > 0 then
        local rewardTimes = repeatRewardAt[player] or {}
        repeatRewardAt[player] = rewardTimes
        local rewardKey = category .. "/" .. id
        local now = os.clock()
        local last = rewardTimes[rewardKey]

        if last and now - last < REPEAT_REWARD_COOLDOWN_SECONDS then
            reward = 0
        else
            rewardTimes[rewardKey] = now
        end
    end

    local awarded = 0

    if reward > 0 then
        awarded = PlayerProgress.AddXP(player, reward, if firstTime then string.format("Completed %s", label) else string.format("Replayed %s", label))
    else
        changed(player, profile)
    end

    return firstTime, awarded
end

function PlayerProgress.IncrementStat(player: Player, stat: string, amount: number?)
    local profile = profiles[player]

    if not profile then
        return
    end

    profile.Stats[stat] = (profile.Stats[stat] or 0) + (amount or 1)
    changed(player, profile)
end

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

-- Counts today's visit toward the streak and pays the visit reward the first time each day.
-- Players who stay in a server past midnight UTC get it when ProgressionService checks again.
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

local function closeSession(player: Player, session: any, snapshot: Profile)
    closingCount += 1
    local saved = session:Close(snapshot)
    closingCount -= 1

    if not saved and not session.Lost then
        warn(string.format("[PlayerProgress] Final save failed for %s; progress since the last autosave is lost", player.Name))
    end
end

function PlayerProgress.Load(player: Player)
    local raw = nil
    local session = nil

    if sessionStore then
        session, raw = sessionStore:Open(keyFor(player.UserId), { player.UserId })
    end

    if not player.Parent then
        -- The player left while the load was waiting: hand the lock straight back.
        if session then
            closeSession(player, session, Progression.Sanitize(raw))
        end

        return
    end

    local profile = Progression.Sanitize(raw)
    profiles[player] = profile
    sessions[player] = session

    if sessionStore and not session then
        toast(player, "warning", "Progress could not load", "You can keep playing, but progress from this visit will not be saved.")
    end

    -- Badges added in an update are granted to players who already qualify.
    awardNewBadges(player, profile)
    applyAttributes(player, profile)
    PlayerProgress.RecordDailyVisit(player)
    PlayerProgress.SendSnapshot(player)
end

-- Saves the profile if it changed, or if the session lock is due for a refresh. Saves of one
-- player never overlap (SessionStore queues them), so an older snapshot cannot land last.
function PlayerProgress.Save(player: Player)
    local profile = profiles[player]
    local session = sessions[player]

    if not profile or not session or session.Lost then
        return
    end

    local lockDue = os.time() - session.LastSavedAt >= LOCK_REFRESH_SECONDS

    if not dirty[player] and not lockDue then
        return
    end

    dirty[player] = nil

    if session:Save(table.clone(profile)) then
        return
    end

    if session.Lost then
        toast(player, "warning", "Progress is open in another server", "Rejoin this game to keep saving your progress.")
    else
        dirty[player] = true
        warn(string.format("[PlayerProgress] Save failed for %s; will retry at the next autosave", player.Name))
    end
end

-- Final save and lock release when the player leaves. The profile is dropped first, so
-- nothing can change it after the final snapshot is taken.
function PlayerProgress.Release(player: Player)
    local profile = profiles[player]
    local session = sessions[player]

    profiles[player] = nil
    sessions[player] = nil
    dirty[player] = nil
    repeatRewardAt[player] = nil

    if profile and session and not session.Lost then
        closeSession(player, session, table.clone(profile))
    end
end

-- BindToClose: release everyone still loaded, then wait for every final save in flight,
-- including the ones PlayerRemoving started.
function PlayerProgress.SaveAll()
    for player in pairs(profiles) do
        task.spawn(PlayerProgress.Release, player)
    end

    local deadline = os.clock() + SHUTDOWN_SAVE_SECONDS

    while closingCount > 0 and os.clock() < deadline do
        task.wait(0.1)
    end
end

return PlayerProgress
