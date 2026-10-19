--!strict

-- Pure progression rules shared by the server (which owns the saved profile) and the
-- client (which only displays it). Nothing here touches Roblox services, so the rules
-- can be unit tested outside Studio.

local BattleScenarios = require(script.Parent.Parent.Data.BattleScenarios)
local CompanionStories = require(script.Parent.Parent.Data.CompanionStories)
local IslamicStudies = require(script.Parent.Parent.Data.IslamicStudies)
local MannersLessons = require(script.Parent.Parent.Data.MannersLessons)

export type Profile = {
    Version: number,
    XP: number,
    Completed: { [string]: { [string]: boolean } },
    Badges: { [string]: number },
    Stats: { [string]: number },
}

export type Badge = {
    Id: string,
    DisplayName: string,
    Description: string,
    -- Optional Roblox badge to award alongside the in-game one. 0 = not configured yet.
    RobloxBadgeId: number,
    IsEarned: (profile: Profile) -> boolean,
}

local Progression = {}

Progression.ProfileVersion = 1

-- Activity categories a profile tracks completion for.
Progression.Categories = {
    Lesson = "lesson",
    Story = "story",
    Battle = "battle",
    Trail = "trail",
    Manners = "manners",
}

-- XP for the first completion of each kind of activity. Repeats give RepeatMultiplier of it,
-- so replaying is still rewarded without making grinding the fastest path.
Progression.Rewards = {
    lesson = 60,
    story = 120,
    battle = 150,
    trail = 90,
    manners = 25,
    TriviaCorrect = 4,
    StudyCircle = 40,
    RepeatMultiplier = 0.25,
}

Progression.RankTitles = {
    { MinLevel = 1, Title = "Seeker" },
    { MinLevel = 3, Title = "Student" },
    { MinLevel = 6, Title = "Student Of Knowledge" },
    { MinLevel = 10, Title = "Scholar's Companion" },
    { MinLevel = 15, Title = "Guardian Of Knowledge" },
}

function Progression.NewProfile(): Profile
    local completed = {}

    for _, category in pairs(Progression.Categories) do
        completed[category] = {}
    end

    return {
        Version = Progression.ProfileVersion,
        XP = 0,
        Completed = completed,
        Badges = {},
        Stats = {},
    }
end

-- Accepts whatever came back from the DataStore and returns a well-formed profile,
-- keeping every valid field and dropping anything malformed.
function Progression.Sanitize(raw: any): Profile
    local profile = Progression.NewProfile()

    if type(raw) ~= "table" then
        return profile
    end

    if type(raw.XP) == "number" and raw.XP >= 0 then
        profile.XP = math.floor(raw.XP)
    end

    if type(raw.Completed) == "table" then
        for category, entries in pairs(raw.Completed) do
            if type(category) == "string" and type(entries) == "table" then
                local target = profile.Completed[category] or {}

                for id, done in pairs(entries) do
                    if type(id) == "string" and done == true then
                        target[id] = true
                    end
                end

                profile.Completed[category] = target
            end
        end
    end

    if type(raw.Badges) == "table" then
        for id, earnedAt in pairs(raw.Badges) do
            if type(id) == "string" and type(earnedAt) == "number" then
                profile.Badges[id] = earnedAt
            end
        end
    end

    if type(raw.Stats) == "table" then
        for stat, value in pairs(raw.Stats) do
            if type(stat) == "string" and type(value) == "number" then
                profile.Stats[stat] = value
            end
        end
    end

    return profile
end

-- XP needed to go from `level` to `level + 1`.
function Progression.XPForNextLevel(level: number): number
    return 100 + (level - 1) * 60
end

function Progression.GetLevelInfo(totalXP: number): { Level: number, XPIntoLevel: number, XPForNext: number }
    local level = 1
    local remaining = math.max(0, math.floor(totalXP))

    while remaining >= Progression.XPForNextLevel(level) do
        remaining -= Progression.XPForNextLevel(level)
        level += 1
    end

    return {
        Level = level,
        XPIntoLevel = remaining,
        XPForNext = Progression.XPForNextLevel(level),
    }
end

function Progression.GetRankTitle(level: number): string
    local title = Progression.RankTitles[1].Title

    for _, rank in ipairs(Progression.RankTitles) do
        if level >= rank.MinLevel then
            title = rank.Title
        end
    end

    return title
end

function Progression.GetCompletionReward(category: string, firstTime: boolean): number
    local base = (Progression.Rewards :: any)[category]

    if type(base) ~= "number" then
        return 0
    end

    if firstTime then
        return base
    end

    return math.floor(base * Progression.Rewards.RepeatMultiplier)
end

local function countCompleted(profile: Profile, category: string, ids: { string }): number
    local entries = profile.Completed[category] or {}
    local count = 0

    for _, id in ipairs(ids) do
        if entries[id] then
            count += 1
        end
    end

    return count
end

local function allCompleted(category: string, ids: { string }): (profile: Profile) -> boolean
    return function(profile: Profile): boolean
        return #ids > 0 and countCompleted(profile, category, ids) == #ids
    end
end

local function idsOf(list: { any }): { string }
    local ids = {}

    for _, item in ipairs(list) do
        table.insert(ids, item.Id)
    end

    return ids
end

local function totalCompleted(profile: Profile, category: string): number
    local count = 0

    for _ in pairs(profile.Completed[category] or {}) do
        count += 1
    end

    return count
end

local function buildBadges(): { Badge }
    local badges: { Badge } = {
        {
            Id = "first_lesson",
            DisplayName = "First Step",
            Description = "Complete your first Islamic Studies lesson.",
            RobloxBadgeId = 0,
            IsEarned = function(profile)
                return totalCompleted(profile, Progression.Categories.Lesson) >= 1
            end,
        },
    }

    for _, unit in ipairs(IslamicStudies.Units) do
        table.insert(badges, {
            Id = string.format("unit_%s", unit.Id),
            DisplayName = string.format("%s Complete", unit.DisplayName),
            Description = string.format("Pass every lesson in %s.", unit.DisplayName),
            RobloxBadgeId = 0,
            IsEarned = allCompleted(Progression.Categories.Lesson, idsOf(unit.Lessons)),
        })
    end

    table.insert(badges, {
        Id = "companion_friend",
        DisplayName = "Friend Of The Sahabah",
        Description = "Finish every companion story.",
        RobloxBadgeId = 0,
        IsEarned = allCompleted(Progression.Categories.Story, idsOf(CompanionStories)),
    })

    table.insert(badges, {
        Id = "adab_keeper",
        DisplayName = "Keeper Of Adab",
        Description = "Read every lesson in the Manners Court.",
        RobloxBadgeId = 0,
        IsEarned = allCompleted(Progression.Categories.Manners, idsOf(MannersLessons)),
    })

    table.insert(badges, {
        Id = "haram_walker",
        DisplayName = "Haram Learning Walk",
        Description = "Finish the learning walk around the Haram.",
        RobloxBadgeId = 0,
        IsEarned = function(profile)
            return totalCompleted(profile, Progression.Categories.Trail) >= 1
        end,
    })

    for _, scenario in ipairs(BattleScenarios) do
        table.insert(badges, {
            Id = string.format("battle_%s", scenario.Id),
            DisplayName = string.format("%s Complete", scenario.DisplayName),
            Description = string.format("Complete the %s experience.", scenario.DisplayName),
            RobloxBadgeId = 0,
            IsEarned = allCompleted(Progression.Categories.Battle, { scenario.Id }),
        })
    end

    table.insert(badges, {
        Id = "study_circle",
        DisplayName = "Halaqah Member",
        Description = "Pass a study circle with other players.",
        RobloxBadgeId = 0,
        IsEarned = function(profile)
            return (profile.Stats.StudyCircles or 0) >= 1
        end,
    })

    table.insert(badges, {
        Id = "trivia_25",
        DisplayName = "Quick Thinker",
        Description = "Answer 25 trivia questions correctly.",
        RobloxBadgeId = 0,
        IsEarned = function(profile)
            return (profile.Stats.TriviaCorrect or 0) >= 25
        end,
    })

    for _, milestone in ipairs({ 5, 10 }) do
        table.insert(badges, {
            Id = string.format("level_%d", milestone),
            DisplayName = string.format("Level %d", milestone),
            Description = string.format("Reach level %d.", milestone),
            RobloxBadgeId = 0,
            IsEarned = function(profile)
                return Progression.GetLevelInfo(profile.XP).Level >= milestone
            end,
        })
    end

    return badges
end

Progression.Badges = buildBadges()

-- Returns why a battle is still locked for this profile, or nil when the player may join.
-- A missing profile (still loading, or the DataStore is down) never locks anyone out.
function Progression.GetBattleLockReason(profile: Profile?, scenarioId: string): string?
    local scenario = nil

    for _, candidate in ipairs(BattleScenarios) do
        if candidate.Id == scenarioId then
            scenario = candidate
        end
    end

    local unlock = scenario and (scenario :: any).Unlock

    if not profile or not unlock then
        return nil
    end

    local battlesDone = profile.Completed[Progression.Categories.Battle] or {}

    if unlock.AfterBattleId and battlesDone[unlock.AfterBattleId] then
        return nil
    end

    if unlock.OrLevel and Progression.GetLevelInfo(profile.XP).Level >= unlock.OrLevel then
        return nil
    end

    local requiredName = unlock.AfterBattleId

    for _, candidate in ipairs(BattleScenarios) do
        if candidate.Id == unlock.AfterBattleId then
            requiredName = candidate.DisplayName
        end
    end

    if unlock.OrLevel then
        return string.format("%s unlocks after you complete the %s or reach level %d.", scenario.DisplayName, requiredName, unlock.OrLevel)
    end

    return string.format("%s unlocks after you complete the %s.", scenario.DisplayName, requiredName)
end

-- Returns the badges the profile now qualifies for but has not been given yet.
function Progression.FindNewBadges(profile: Profile): { Badge }
    local earned = {}

    for _, badge in ipairs(Progression.Badges) do
        if not profile.Badges[badge.Id] and badge.IsEarned(profile) then
            table.insert(earned, badge)
        end
    end

    return earned
end

-- What the client is sent: plain data only, no functions.
function Progression.BuildSnapshot(profile: Profile)
    local levelInfo = Progression.GetLevelInfo(profile.XP)
    local badges = {}

    for _, badge in ipairs(Progression.Badges) do
        table.insert(badges, {
            Id = badge.Id,
            DisplayName = badge.DisplayName,
            Description = badge.Description,
            Earned = profile.Badges[badge.Id] ~= nil,
        })
    end

    local completed = {}

    for category, entries in pairs(profile.Completed) do
        local ids = {}

        for id in pairs(entries) do
            table.insert(ids, id)
        end

        table.sort(ids)
        completed[category] = ids
    end

    return {
        XP = profile.XP,
        Level = levelInfo.Level,
        XPIntoLevel = levelInfo.XPIntoLevel,
        XPForNext = levelInfo.XPForNext,
        RankTitle = Progression.GetRankTitle(levelInfo.Level),
        Badges = badges,
        Completed = completed,
        Stats = table.clone(profile.Stats),
    }
end

return Progression
