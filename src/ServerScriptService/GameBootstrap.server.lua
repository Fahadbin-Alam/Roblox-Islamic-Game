--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ContentIndex = require(Shared.Modules.ContentIndex)

local function ensureFolder(parent: Instance, name: string): Folder
    local existing = parent:FindFirstChild(name)

    if existing then
        if existing:IsA("Folder") then
            return existing
        end

        error(string.format("Expected Folder named %s under %s, found %s", name, parent:GetFullName(), existing.ClassName))
    end

    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = parent

    return folder
end

local function ensureRemoteEvent(parent: Instance, name: string): RemoteEvent
    local existing = parent:FindFirstChild(name)

    if existing then
        if existing:IsA("RemoteEvent") then
            return existing
        end

        error(string.format("Expected RemoteEvent named %s under %s, found %s", name, parent:GetFullName(), existing.ClassName))
    end

    local remoteEvent = Instance.new("RemoteEvent")
    remoteEvent.Name = name
    remoteEvent.Parent = parent

    return remoteEvent
end

local content = ContentIndex.GetStartupPayload()
local remotesFolder = ensureFolder(ReplicatedStorage, "Remotes")

local storyFolder = ensureFolder(remotesFolder, "Story")
local battleFolder = ensureFolder(remotesFolder, "Battle")
local shopFolder = ensureFolder(remotesFolder, "Shop")
local hubFolder = ensureFolder(remotesFolder, "Hub")
local mannersFolder = ensureFolder(remotesFolder, "Manners")
local triviaFolder = ensureFolder(remotesFolder, "Trivia")
local progressFolder = ensureFolder(remotesFolder, "Progress")
local learningFolder = ensureFolder(remotesFolder, "Learning")

ensureRemoteEvent(hubFolder, "RequestTeleport")
ensureRemoteEvent(hubFolder, "RequestHaramTrail")
ensureRemoteEvent(hubFolder, "ShowLearningTrail")
ensureRemoteEvent(hubFolder, "UpdateLearningTrail")
ensureRemoteEvent(hubFolder, "ClearLearningTrail")
ensureRemoteEvent(battleFolder, "ShowBattleMessage")
ensureRemoteEvent(battleFolder, "ShowBattleSummary")
ensureRemoteEvent(battleFolder, "PlayReenactment")
ensureRemoteEvent(battleFolder, "RequestJoinBattle")
ensureRemoteEvent(battleFolder, "RequestBlock")
ensureRemoteEvent(storyFolder, "ShowStoryDialogue")
ensureRemoteEvent(storyFolder, "UpdateStoryMission")
ensureRemoteEvent(storyFolder, "ClearStoryMission")
ensureRemoteEvent(storyFolder, "RequestStartStory")
ensureRemoteEvent(mannersFolder, "RequestLesson")
ensureRemoteEvent(mannersFolder, "ShowMannersLesson")
ensureRemoteEvent(triviaFolder, "RequestStartTrivia")
ensureRemoteEvent(triviaFolder, "SubmitTriviaAnswer")
ensureRemoteEvent(triviaFolder, "ShowTriviaQuestion")
ensureRemoteEvent(triviaFolder, "ShowTriviaResult")
ensureRemoteEvent(triviaFolder, "UpdateTriviaScores")
ensureRemoteEvent(triviaFolder, "ClearTrivia")
ensureRemoteEvent(progressFolder, "RequestProfile")
ensureRemoteEvent(progressFolder, "ProfileUpdated")
ensureRemoteEvent(progressFolder, "ProgressToast")
ensureRemoteEvent(learningFolder, "OpenLearningHall")
ensureRemoteEvent(learningFolder, "SubmitQuiz")
ensureRemoteEvent(learningFolder, "QuizResult")
ensureRemoteEvent(learningFolder, "StudyCircleUpdate")
ensureRemoteEvent(learningFolder, "StudyCircleAnswer")
ensureRemoteEvent(shopFolder, "RequestShopState")
ensureRemoteEvent(shopFolder, "PromptGamePassPurchase")
ensureRemoteEvent(shopFolder, "PromptDeveloperProductPurchase")
ensureRemoteEvent(shopFolder, "EquipSkin")
ensureRemoteEvent(shopFolder, "UseUltimate")
ensureRemoteEvent(shopFolder, "ShopState")
ensureRemoteEvent(shopFolder, "PurchaseFeedback")

print(string.format(
    "[GameBootstrap] %s loaded with %d stories, %d Islamic Studies units, %d battle scenarios, %d travel landmarks, and %d premium products.",
    content.Config.GameName,
    #content.Stories,
    #content.IslamicStudies.Units,
    #content.Battles,
    #content.TravelRoute.Destinations,
    #content.Shop.GamePasses + #content.Shop.DeveloperProducts
))
