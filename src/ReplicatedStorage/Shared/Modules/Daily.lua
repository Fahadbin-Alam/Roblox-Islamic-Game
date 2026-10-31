--!strict

-- Pure rules for the daily return loop: one reflection and one review question per day, plus
-- a visit streak. Days are counted in UTC so every server agrees on when a new day starts.

local DailyReflections = require(script.Parent.Parent.Data.DailyReflections)
local IslamicStudies = require(script.Parent.Parent.Data.IslamicStudies)

local Daily = {}

local SECONDS_PER_DAY = 86400

Daily.Rewards = {
    VisitBase = 20,
    -- Each consecutive day adds this much, up to a week of growth.
    VisitPerStreakDay = 5,
    VisitStreakCap = 7,
    Question = 30,
}

type Stats = { [string]: number }

local allQuestions = {}

for _, unit in ipairs(IslamicStudies.Units) do
    for _, lesson in ipairs(unit.Lessons) do
        for index, question in ipairs(lesson.Quiz) do
            table.insert(allQuestions, {
                LessonId = lesson.Id,
                LessonName = lesson.DisplayName,
                QuestionIndex = index,
                Question = question,
            })
        end
    end
end

function Daily.DayNumber(unixTime: number): number
    return math.floor(unixTime / SECONDS_PER_DAY)
end

function Daily.GetReflection(day: number)
    return DailyReflections[(day % #DailyReflections) + 1]
end

local function gcd(a: number, b: number): number
    while b ~= 0 do
        a, b = b, a % b
    end

    return a
end

-- Stepping by a number coprime with the question count spreads consecutive days across
-- different lessons and still reaches every question before repeating.
local questionStep = 1

for _, candidate in ipairs({ 7, 11, 13, 17, 19, 23 }) do
    if gcd(candidate, #allQuestions) == 1 then
        questionStep = candidate
        break
    end
end

function Daily.GetQuestion(day: number)
    local index = ((day * questionStep) % #allQuestions) + 1
    return allQuestions[index]
end

function Daily.QuestionCount(): number
    return #allQuestions
end

function Daily.VisitReward(streak: number): number
    local growth = math.min(math.max(streak, 1), Daily.Rewards.VisitStreakCap) - 1
    return Daily.Rewards.VisitBase + growth * Daily.Rewards.VisitPerStreakDay
end

-- Records a visit on `day`. Returns the new streak and whether this is the first visit today.
-- Missing a day resets the streak to 1.
function Daily.RecordVisit(stats: Stats, day: number): (number, boolean)
    local lastDay = stats.DailyLastDay

    if lastDay == day then
        return stats.DailyStreak or 1, false
    end

    local streak = if lastDay == day - 1 then (stats.DailyStreak or 0) + 1 else 1
    stats.DailyLastDay = day
    stats.DailyStreak = streak
    stats.DailyBestStreak = math.max(stats.DailyBestStreak or 0, streak)

    return streak, true
end

function Daily.HasAnsweredQuestion(stats: Stats, day: number): boolean
    return stats.DailyQuestionDay == day
end

-- What the client is shown for today. The correct answer is left out on purpose.
function Daily.BuildPayload(stats: Stats, day: number)
    local reflection = Daily.GetReflection(day)
    local entry = Daily.GetQuestion(day)

    return {
        Day = day,
        Streak = stats.DailyStreak or 0,
        BestStreak = stats.DailyBestStreak or 0,
        Reflection = {
            Text = reflection.Text,
            Source = reflection.Source,
            Thought = reflection.Thought,
        },
        Question = {
            LessonName = entry.LessonName,
            Prompt = entry.Question.Prompt,
            Options = entry.Question.Options,
        },
        QuestionAnswered = Daily.HasAnsweredQuestion(stats, day),
        QuestionReward = Daily.Rewards.Question,
    }
end

return Daily
