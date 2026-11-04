--!strict

local GameConfig = require(script.Parent.Parent.Config.GameConfig)
local BattleScenarios = require(script.Parent.Parent.Data.BattleScenarios)
local CompanionStories = require(script.Parent.Parent.Data.CompanionStories)
local HaramLearningTrail = require(script.Parent.Parent.Data.HaramLearningTrail)
local IslamicStudies = require(script.Parent.Parent.Data.IslamicStudies)
local MannersLessons = require(script.Parent.Parent.Data.MannersLessons)
local ShopCatalog = require(script.Parent.Parent.Data.ShopCatalog)
local TravelRoute = require(script.Parent.Parent.Data.TravelRoute)
local TriviaQuestions = require(script.Parent.Parent.Data.TriviaQuestions)

local ContentIndex = {}

function ContentIndex.GetStartupPayload()
    return {
        Config = GameConfig,
        Battles = BattleScenarios,
        Stories = CompanionStories,
        HaramLearningTrail = HaramLearningTrail,
        IslamicStudies = IslamicStudies,
        Manners = MannersLessons,
        Shop = ShopCatalog,
        TravelRoute = TravelRoute,
        Trivia = TriviaQuestions,
    }
end

return ContentIndex
