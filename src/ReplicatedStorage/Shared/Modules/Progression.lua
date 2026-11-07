--!strict

-- Pure progression rules shared by the server (which owns the saved profile) and the
-- client (which only displays it). Nothing here touches Roblox services, so the rules
-- can be unit tested outside Studio.

local BattleMissions = require(script.Parent.Parent.Data.BattleMissions)
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
    Path = "path",
    Order = "order",
    Reflection = "reflection",
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
    path = 25,
    order = 30,
    reflection = 15,
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

    local orderLessonIds = {}

    for _, unit in ipairs(IslamicStudies.Units) do
        for _, lesson in ipairs(unit.Lessons) do
            if lesson.Order then
                table.insert(orderLessonIds, lesson.Id)
            end
        end
    end

    table.insert(badges, {
        Id = "puzzle_master",
        DisplayName = "In The Right Order",
        Description = "Solve every order puzzle in the Islamic Studies hall.",
        RobloxBadgeId = 0,
        IsEarned = allCompleted(Progression.Categories.Order, orderLessonIds),
    })

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
        Id = "badr_three_stars",
        DisplayName = "Defender Of The Wells",
        Description = "Earn all three stars in the Battle of Badr story mission.",
        RobloxBadgeId = 0,
        IsEarned = function(profile)
            return (profile.Stats.BestStars_badr or 0) >= 3
        end,
    })

    table.insert(badges, {
        Id = "uhud_kept_post",
        DisplayName = "Kept The Post",
        Description = "Stay on the Archers' Hill through the test of the spoils at Uhud.",
        RobloxBadgeId = 0,
        IsEarned = function(profile)
            return (profile.Stats.UhudPostKept or 0) >= 1
        end,
    })

    table.insert(badges, {
        Id = "uhud_three_stars",
        DisplayName = "Steadfast At Uhud",
        Description = "Earn all three stars in the Battle of Uhud story mission.",
        RobloxBadgeId = 0,
        IsEarned = function(profile)
            return (profile.Stats.BestStars_uhud or 0) >= 3
        end,
    })

    local reflectionIds = {}

    for _, missionId in ipairs(BattleMissions.Order) do
        for _, question in ipairs(BattleMissions.Get(missionId).Reflection) do
            table.insert(reflectionIds, question.Id)
        end
    end

    table.insert(badges, {
        Id = "battle_lessons",
        DisplayName = "Lessons Of The Battles",
        Description = "Answer every after-battle reflection question correctly.",
        RobloxBadgeId = 0,
        IsEarned = allCompleted(Progression.Categories.Reflection, reflectionIds),
    })

    table.insert(badges, {
        Id = "battle_veteran",
        DisplayName = "Steady In Every Step",
        Description = "Complete 40 battle mission objectives.",
        RobloxBadgeId = 0,
        IsEarned = function(profile)
            return (profile.Stats.BattleObjectives or 0) >= 40
        end,
    })

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

local function lessonIdsOfUnit(unitId: string): { string }
    for _, unit in ipairs(IslamicStudies.Units) do
        if unit.Id == unitId then
            return idsOf(unit.Lessons)
        end
    end

    return {}
end

local function allLessonIds(): { string }
    local ids = {}

    for _, unit in ipairs(IslamicStudies.Units) do
        for _, lesson in ipairs(unit.Lessons) do
            table.insert(ids, lesson.Id)
        end
    end

    return ids
end

export type PathStep = {
    Id: string,
    Title: string,
    Hint: string,
    -- Where a guide can send the player for this step: a TravelRoute destination to
    -- teleport to, or an Islamic Studies unit to open.
    Destination: string?,
    HallUnitId: string?,
    IsDone: (profile: Profile) -> boolean,
}

-- The suggested order through the game. Players can do anything at any time; this only
-- powers the "Next" hint and the journal checklist so nobody wonders what to do next.
Progression.Path = {
    {
        Id = "haram_walk",
        Destination = "kaaba_courtyard",
        Title = "Take the Haram Learning Walk",
        Hint = "Start at the gold marker on the south side of the Kaaba courtyard.",
        IsDone = function(profile)
            return totalCompleted(profile, Progression.Categories.Trail) >= 1
        end,
    },
    {
        Id = "pillars",
        HallUnitId = "pillars",
        Title = "Learn the Five Pillars",
        Hint = "Press Learn and open The Five Pillars.",
        IsDone = allCompleted(Progression.Categories.Lesson, lessonIdsOfUnit("pillars")),
    },
    {
        Id = "first_story",
        Destination = "story_court",
        Title = "Finish a companion story",
        Hint = "Open the Menu, choose Learn About Sahabis, and pick a companion.",
        IsDone = function(profile)
            return totalCompleted(profile, Progression.Categories.Story) >= 1
        end,
    },
    {
        Id = "badr",
        Destination = "badr_gate",
        Title = "Complete the Battle of Badr",
        Hint = "Open the Menu and choose Battle of Badr.",
        IsDone = allCompleted(Progression.Categories.Battle, { "badr" }),
    },
    {
        Id = "prayer",
        HallUnitId = "prayer",
        Title = "Learn how to pray",
        Hint = "Press Learn and open How To Pray.",
        IsDone = allCompleted(Progression.Categories.Lesson, lessonIdsOfUnit("prayer")),
    },
    {
        Id = "manners",
        Destination = "manners_court",
        Title = "Read every Manners Court lesson",
        Hint = "Walk to the Manners Court and read each board.",
        IsDone = allCompleted(Progression.Categories.Manners, idsOf(MannersLessons)),
    },
    {
        Id = "uhud",
        Destination = "uhud_gate",
        Title = "Complete the Battle of Uhud",
        Hint = "Open the Menu and choose Battle of Uhud.",
        IsDone = allCompleted(Progression.Categories.Battle, { "uhud" }),
    },
    {
        Id = "study_circle",
        Destination = "trivia_court",
        Title = "Pass a study circle with a friend",
        Hint = "Stand by the Islamic Studies podium in the Trivia Court with a friend and start a circle.",
        IsDone = function(profile)
            return (profile.Stats.StudyCircles or 0) >= 1
        end,
    },
    {
        Id = "all_lessons",
        Title = "Finish every Islamic Studies lesson",
        Hint = "Press Learn and complete the lessons you have left.",
        IsDone = allCompleted(Progression.Categories.Lesson, allLessonIds()),
    },
} :: { PathStep }

-- Path steps the profile has finished but not yet been rewarded for.
function Progression.FindNewlyCompletedSteps(profile: Profile): { PathStep }
    local rewarded = profile.Completed[Progression.Categories.Path] or {}
    local steps = {}

    for _, step in ipairs(Progression.Path) do
        if not rewarded[step.Id] and step.IsDone(profile) then
            table.insert(steps, step)
        end
    end

    return steps
end

-- The first unfinished step, or nil when the whole path is done.
function Progression.GetNextStep(profile: Profile): PathStep?
    for _, step in ipairs(Progression.Path) do
        if not step.IsDone(profile) then
            return step
        end
    end

    return nil
end

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

    local path = {}

    for _, step in ipairs(Progression.Path) do
        table.insert(path, {
            Id = step.Id,
            Title = step.Title,
            Hint = step.Hint,
            Destination = step.Destination,
            HallUnitId = step.HallUnitId,
            Done = step.IsDone(profile),
        })
    end

    local nextStep = Progression.GetNextStep(profile)

    return {
        XP = profile.XP,
        Path = path,
        NextStep = if nextStep
            then { Id = nextStep.Id, Title = nextStep.Title, Hint = nextStep.Hint, Destination = nextStep.Destination, HallUnitId = nextStep.HallUnitId }
            else nil,
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
