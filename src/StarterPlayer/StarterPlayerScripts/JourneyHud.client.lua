--!strict

-- On-screen guidance for the Seerah campaign, the mystery rooms, parkour runs, the co-op
-- trials, and sparring matches. Everything shown here comes from the server's state messages;
-- the client only displays it and sends the player's choices back.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local UiKit = require(script.Parent:WaitForChild("UiKit"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SeerahCampaign = require(Shared.Data.SeerahCampaign)
local HistoricalSites = require(Shared.Data.HistoricalSites)
local SahabiMysteries = require(Shared.Data.SahabiMysteries)
local BattleScenarios = require(Shared.Data.BattleScenarios)
local ParkourRules = require(Shared.Modules.ParkourRules)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local C = UiKit.Colors

local function remote(folder: string, name: string): RemoteEvent
    return remotes:WaitForChild(folder):WaitForChild(name) :: RemoteEvent
end

local campaignRequest, campaignState = remote("Campaign", "Request"), remote("Campaign", "State")
local mysteryRequest, mysteryState = remote("Mystery", "Request"), remote("Mystery", "State")
local parkourRequest, parkourState = remote("Parkour", "Request"), remote("Parkour", "State")
local coopState = remote("Coop", "State")
local pvpRequest, pvpState = remote("Pvp", "Request"), remote("Pvp", "State")

local chapterById = {}

for _, chapter in ipairs(SeerahCampaign.Chapters) do
    chapterById[chapter.Id] = chapter
end

local mysteryById = {}

for _, mystery in ipairs(SahabiMysteries.Mysteries) do
    mysteryById[mystery.Id] = mystery
end

local gui = Instance.new("ScreenGui")
gui.Name = "JourneyHud"
gui.ResetOnSpawn = false
gui.DisplayOrder = 105
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

-- Toasts ------------------------------------------------------------------------------------

local toasts = Instance.new("Frame")
toasts.BackgroundTransparency = 1
toasts.Size = UDim2.fromOffset(520, 200)
toasts.Position = UDim2.new(0.5, 0, 0, 70)
toasts.AnchorPoint = Vector2.new(0.5, 0)
toasts.Parent = gui

local toastLayout = Instance.new("UIListLayout")
toastLayout.Padding = UDim.new(0, 6)
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
toastLayout.Parent = toasts

local function toast(text: string, color: Color3?)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 0)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.BackgroundColor3 = color or C.Panel
    label.BackgroundTransparency = 0.1
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = C.Text
    label.TextSize = 16
    label.TextWrapped = true
    label.Parent = toasts
    UiKit.Round(label, 8)

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 8)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = label

    task.delay(4.5, function()
        label:Destroy()
    end)
end

-- Modal (story pages, questions, conclusions) -----------------------------------------------

local modal = UiKit.Frame(gui, "Modal", UDim2.fromOffset(640, 440), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
UiKit.FitToScreen(modal)
modal.Visible = false
local modalTitle = UiKit.Label(modal, "", UDim2.new(1, -36, 0, 34), UDim2.fromOffset(18, 14), 22, true, C.Gold)
local modalBody = UiKit.Scroller(modal, UDim2.new(1, -36, 1, -170), UDim2.fromOffset(18, 54))
local modalButtons = Instance.new("Frame")
modalButtons.BackgroundTransparency = 1
modalButtons.Size = UDim2.new(1, -36, 0, 100)
modalButtons.Position = UDim2.new(0, 18, 1, -110)
modalButtons.Parent = modal

local buttonGrid = Instance.new("UIGridLayout")
buttonGrid.CellSize = UDim2.new(0.5, -6, 0, 44)
buttonGrid.CellPadding = UDim2.fromOffset(8, 8)
buttonGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
buttonGrid.Parent = modalButtons

type ButtonSpec = { Text: string, Color: Color3?, OnClick: () -> () }

local modalOwner = ""

local function showModal(owner: string, title: string, paragraphs: { string }, buttons: { ButtonSpec })
    modalOwner = owner
    modalTitle.Text = title
    UiKit.Clear(modalBody)
    UiKit.Clear(modalButtons)

    for index, text in ipairs(paragraphs) do
        UiKit.Paragraph(modalBody, text, 16).LayoutOrder = index
    end

    for _, spec in ipairs(buttons) do
        UiKit.Button(modalButtons, spec.Text, UDim2.new(), UDim2.new(), spec.Color, spec.OnClick)
    end

    modalBody.CanvasPosition = Vector2.zero
    modal.Visible = true
end

local function hideModal(owner: string?)
    if owner == nil or modalOwner == owner then
        modal.Visible = false
        modalOwner = ""
    end
end

-- Seerah campaign ---------------------------------------------------------------------------

local card = UiKit.Frame(gui, "CampaignCard", UDim2.fromOffset(560, 118), UDim2.new(0.5, 0, 1, -16), Vector2.new(0.5, 1))
card.Visible = false
local cardTitle = UiKit.Label(card, "", UDim2.new(1, -24, 0, 22), UDim2.fromOffset(12, 8), 17, true, C.Gold)
local cardBody = UiKit.Label(card, "", UDim2.new(1, -24, 0, 40), UDim2.fromOffset(12, 32), 14)
local cardButtons = Instance.new("Frame")
cardButtons.BackgroundTransparency = 1
cardButtons.Size = UDim2.new(1, -24, 0, 36)
cardButtons.Position = UDim2.new(0, 12, 1, -42)
cardButtons.Parent = card

local cardLayout = Instance.new("UIListLayout")
cardLayout.FillDirection = Enum.FillDirection.Horizontal
cardLayout.Padding = UDim.new(0, 8)
cardLayout.Parent = cardButtons

local function setCard(title: string, body: string, buttons: { ButtonSpec })
    cardTitle.Text = title
    cardBody.Text = body
    UiKit.Clear(cardButtons)

    for _, spec in ipairs(buttons) do
        UiKit.Button(cardButtons, spec.Text, UDim2.fromOffset(160, 34), UDim2.new(), spec.Color, spec.OnClick)
    end

    card.Visible = true
end

local campaign = { Run = nil :: any, StoryPage = 1, LastStage = "", LastChapter = "" }
local marker: Part? = nil

local function clearMarker()
    if marker then
        marker:Destroy()
        marker = nil
    end
end

-- A tall light at the chapter's site, visible only to this player.
local function showMarker(position: Vector3)
    clearMarker()
    local beam = Instance.new("Part")
    beam.Name = "ChapterMarker"
    beam.Anchored = true
    beam.CanCollide = false
    beam.CanQuery = false
    beam.CanTouch = false
    beam.Material = Enum.Material.Neon
    beam.Color = C.Gold
    beam.Transparency = 0.45
    beam.Size = Vector3.new(2, 120, 2)
    beam.CFrame = CFrame.new(position + Vector3.new(0, 60, 0))
    beam.Parent = Workspace
    marker = beam
end

-- Collect items: show only this chapter's, and only the ones not yet picked up.
local function updateItems(run: any)
    local world = Workspace:FindFirstChild(HistoricalSites.FolderName)
    local items = world and world:FindFirstChild("CampaignItems")

    if not items then
        return
    end

    local collected = {}

    if run then
        for _, index in ipairs(run.Collected or {}) do
            collected[index] = true
        end
    end

    for _, folder in ipairs(items:GetChildren()) do
        local active = run ~= nil and run.Stage == "Activity" and folder.Name == run.ChapterId

        for _, item in ipairs(folder:GetChildren()) do
            if item:IsA("BasePart") then
                local visible = active and not collected[item:GetAttribute("ItemIndex") :: number]
                item.Transparency = if visible then 0.1 else 1
                local prompt = item:FindFirstChildOfClass("ProximityPrompt")

                if prompt then
                    prompt.Enabled = visible
                end
            end
        end
    end
end

local function battleName(scenarioId: string?): string
    for _, scenario in ipairs(BattleScenarios) do
        if scenario.Id == scenarioId then
            return scenario.DisplayName
        end
    end

    return "the battle"
end

local function peopleText(chapter: any): string
    local lines = {}

    for _, person in ipairs(chapter.People) do
        table.insert(lines, string.format("• <b>%s</b>: %s", person.Name, person.Role))
    end

    return table.concat(lines, "\n")
end

local function showStoryPage(chapter: any)
    local page = campaign.StoryPage
    local total = #chapter.Story
    local paragraphs = { chapter.Story[page] }

    if page == 1 then
        table.insert(paragraphs, 1, string.format("<i>%s · %s</i>", chapter.When, (HistoricalSites.GetSite(chapter.Site) :: any).DisplayName))
        table.insert(paragraphs, "<b>People in this chapter</b>\n" .. peopleText(chapter))
    end

    local buttons: { ButtonSpec } = {}

    if page > 1 then
        table.insert(buttons, {
            Text = "Back",
            Color = C.PanelLight,
            OnClick = function()
                campaign.StoryPage -= 1
                showStoryPage(chapter)
            end,
        })
    end

    table.insert(buttons, {
        Text = if page < total then "Next" else "Continue",
        OnClick = function()
            if page < total then
                campaign.StoryPage += 1
                showStoryPage(chapter)
            else
                hideModal("campaign")
                campaignRequest:FireServer("FinishStory")
            end
        end,
    })

    showModal("campaign", string.format("Chapter %d: %s  (%d/%d)", chapter.Number, chapter.Title, page, total), paragraphs, buttons)
end

local function showDecision(chapter: any, retryText: string?)
    local buttons: { ButtonSpec } = {}

    for index, option in ipairs(chapter.Decision.Options) do
        table.insert(buttons, {
            Text = option,
            Color = C.Blue,
            OnClick = function()
                campaignRequest:FireServer("Answer", index)
            end,
        })
    end

    local paragraphs = { chapter.Decision.Prompt }

    if retryText then
        table.insert(paragraphs, string.format("<font color=\"#E2BA60\">%s</font>", retryText))
    end

    -- Four options need two rows of buttons; make room.
    showModal("campaign", string.format("Chapter %d: what happened?", chapter.Number), paragraphs, buttons)
end

local function showConclusion(chapter: any, explanation: string)
    local sources = {}

    for _, source in ipairs(chapter.Sources) do
        table.insert(sources, "• " .. source)
    end

    local nextChapter = SeerahCampaign.Chapters[chapter.Number + 1]
    local buttons: { ButtonSpec } = {
        {
            Text = "Close",
            Color = C.PanelLight,
            OnClick = function()
                hideModal("campaign")
                campaignRequest:FireServer("Close")
            end,
        },
    }

    if nextChapter then
        table.insert(buttons, {
            Text = "Next chapter",
            OnClick = function()
                hideModal("campaign")
                campaignRequest:FireServer("Start", nextChapter.Id)
            end,
        })
    end

    showModal("campaign", string.format("Chapter %d complete: %s", chapter.Number, chapter.Title), {
        "<b>Correct.</b> " .. explanation,
        "<b>What happened next</b>\n" .. chapter.Consequence,
        "<b>Lesson</b>\n" .. chapter.Lesson,
        "<b>Sources</b>\n" .. table.concat(sources, "\n"),
        "<b>History and gameplay</b>\n" .. chapter.GameplayNote,
    }, buttons)
end

local function renderCampaign(data: any)
    local run = data.Run
    campaign.Run = run
    updateItems(run)

    if not run then
        card.Visible = false
        clearMarker()
        hideModal("campaign")
        return
    end

    local chapter = chapterById[run.ChapterId]
    local site = chapter and HistoricalSites.GetSite(chapter.Site)

    if not chapter or not site then
        return
    end

    local changed = run.Stage ~= campaign.LastStage or run.ChapterId ~= campaign.LastChapter
    campaign.LastStage = run.Stage
    campaign.LastChapter = run.ChapterId
    local heading = string.format("Seerah %d/30 · %s", chapter.Number, chapter.Title)
    local quit = { Text = "Leave chapter", Color = C.PanelLight, OnClick = function()
        campaignRequest:FireServer("Close")
    end }

    if run.Stage == "Travel" then
        showMarker(HistoricalSites.ArrivalPoint(site))
        hideModal("campaign")
        setCard(heading, string.format("Go to <b>%s</b>. Follow the golden light and stand in the ring.%s", site.DisplayName, if site.Kind == "Mountain" then " Climb the ramps to the cave ledge." else ""), {
            { Text = "Travel there", OnClick = function()
                campaignRequest:FireServer("Travel")
            end },
            quit,
        })
    elseif run.Stage == "Story" then
        clearMarker()
        card.Visible = false

        if changed then
            campaign.StoryPage = 1
        end

        showStoryPage(chapter)
    elseif run.Stage == "Activity" then
        hideModal("campaign")
        local activity = chapter.Activity

        if not activity then
            return
        end

        if activity.Kind == "Collect" then
            showMarker(HistoricalSites.ArrivalPoint(site))
            setCard(heading, string.format("Find %d %s%s around %s (%d/%d). Glowing objects are game items.", activity.Count, activity.Item, if activity.Count > 1 then "s" else "", site.DisplayName, #(run.Collected or {}), activity.Count), { quit })
        else
            clearMarker()
            setCard(heading, string.format("Play the <b>%s</b> Story Mission, then come back here.", battleName(activity.ScenarioId)), {
                { Text = "Go to the gate", Color = C.Red, OnClick = function()
                    campaignRequest:FireServer("GoBattle")
                end },
                { Text = "I finished it", OnClick = function()
                    campaignRequest:FireServer("CheckBattle")
                end },
                quit,
            })
        end
    elseif run.Stage == "Decision" then
        clearMarker()
        card.Visible = false
        local feedback = data.Feedback

        showDecision(chapter, if feedback and feedback.Kind == "retry" then feedback.Text else nil)
    elseif run.Stage == "Done" then
        clearMarker()
        card.Visible = false
        local feedback = data.Feedback

        if feedback and feedback.Kind == "success" then
            showConclusion(chapter, feedback.Text)
        end
    end

    if data.Feedback and data.Feedback.Kind ~= "retry" and data.Feedback.Kind ~= "success" then
        toast(data.Feedback.Text)
    elseif data.Feedback and data.Feedback.Kind == "success" and run.Stage ~= "Done" then
        toast(data.Feedback.Text, C.Green)
    end
end

campaignState.OnClientEvent:Connect(function(data)
    local ok, err = pcall(renderCampaign, data)

    if not ok then
        warn("[JourneyHud] campaign: " .. tostring(err))
    end
end)

-- Mystery rooms -----------------------------------------------------------------------------

local mysteryCard = UiKit.Frame(gui, "MysteryCard", UDim2.fromOffset(320, 150), UDim2.new(1, -16, 0, 80), Vector2.new(1, 0))
mysteryCard.Visible = false
local mysteryTitle = UiKit.Label(mysteryCard, "", UDim2.new(1, -20, 0, 22), UDim2.fromOffset(10, 8), 16, true, C.Gold)
local mysteryBody = UiKit.Label(mysteryCard, "", UDim2.new(1, -20, 0, 70), UDim2.fromOffset(10, 32), 14)
UiKit.Button(mysteryCard, "Hint", UDim2.fromOffset(90, 30), UDim2.new(0, 10, 1, -38), C.Blue, function()
    mysteryRequest:FireServer("Hint")
end)

local lockAnswers: { number } = {}

local function showLock(mystery: any, questionIndex: number)
    local question = mystery.Lock[questionIndex]
    local buttons: { ButtonSpec } = {}

    for optionIndex, option in ipairs(question.Options) do
        table.insert(buttons, {
            Text = option,
            Color = C.Purple,
            OnClick = function()
                lockAnswers[questionIndex] = optionIndex

                if questionIndex < #mystery.Lock then
                    showLock(mystery, questionIndex + 1)
                else
                    hideModal("mystery")
                    mysteryRequest:FireServer("Lock", lockAnswers)
                end
            end,
        })
    end

    showModal("mystery", string.format("The lock (%d/%d)", questionIndex, #mystery.Lock), { question.Prompt }, buttons)
end

local function showMysteryConclusion(mystery: any, data: any)
    local sources = {}

    for _, source in ipairs(mystery.Sources) do
        table.insert(sources, "• " .. source)
    end

    local paragraphs = { string.format("<b>%s</b>   %s", data.FinishText or mystery.Episode.FinishText, string.rep("★", data.Stars) .. string.rep("☆", 3 - data.Stars)) }

    for _, text in ipairs(mystery.Conclusion) do
        table.insert(paragraphs, text)
    end

    table.insert(paragraphs, "<b>Sources</b>\n" .. table.concat(sources, "\n"))
    table.insert(paragraphs, "<b>History and gameplay</b>\n" .. mystery.FictionNote)

    showModal("mystery", string.format("Solved: %s", mystery.Companion), paragraphs, {
        { Text = "Close", OnClick = function()
            hideModal("mystery")
        end },
    })
end

mysteryState.OnClientEvent:Connect(function(data)
    if not data.InRoom then
        mysteryCard.Visible = false
        hideModal("mystery")
        return
    end

    local mystery = mysteryById[data.MysteryId]

    if not mystery then
        return
    end

    local stage = if data.Done then "Episode complete" elseif data.LockOpen then string.format("Episode: %s. Next: %s", mystery.Episode.Title, if data.NextStation then mystery.Episode.Stations[data.NextStation].Name else "-") else "Examine the objects, then open the lock on the far door."
    mysteryTitle.Text = mystery.Title
    mysteryBody.Text = string.format("Clues %d/%d · Hints used %d · %d here\n%s", #data.Found, #mystery.Clues, data.HintsUsed, data.Players, stage)
    mysteryCard.Visible = true

    if data.ShowClue then
        for _, clue in ipairs(mystery.Clues) do
            if clue.Id == data.ShowClue then
                showModal("mystery", clue.Object, { clue.Text, "<i>This object is a game prop. The event it describes is documented.</i>" }, {
                    { Text = "Close", OnClick = function()
                        hideModal("mystery")
                    end },
                })
            end
        end
    end

    if data.OpenLock and not data.LockOpen then
        lockAnswers = {}
        showLock(mystery, 1)
    end

    if data.Toast then
        toast(data.Toast, C.Purple)
    end

    if data.Finished then
        showMysteryConclusion(mystery, data)
    end

    if data.Reset then
        toast("The room has reset for the next group.")
    end
end)

-- Parkour -----------------------------------------------------------------------------------

local timer = UiKit.Label(gui, "", UDim2.fromOffset(260, 40), UDim2.new(0.5, -130, 0, 24), 26, true, C.Gold)
timer.TextXAlignment = Enum.TextXAlignment.Center
timer.Visible = false
local parkour = { StartedAt = nil :: number?, Offset = 0 }

local checkpointButton = UiKit.Button(gui, "Back to checkpoint", UDim2.fromOffset(170, 36), UDim2.new(0.5, -85, 0, 66), C.Blue, function()
    parkourRequest:FireServer("Checkpoint")
end)
checkpointButton.Visible = false

parkourState.OnClientEvent:Connect(function(data)
    parkour.Offset = (data.ServerNow or Workspace:GetServerTimeNow()) - Workspace:GetServerTimeNow()
    parkour.StartedAt = if data.Active then data.StartedAt else nil
    timer.Visible = data.Active == true
    checkpointButton.Visible = data.Active == true and (data.Checkpoint or 0) >= 2

    if data.Event == "start" then
        toast("Timer started. Gold steps are checkpoints.", C.Green)
    elseif data.Event == "checkpoint" then
        toast(string.format("Checkpoint %d of %d", data.Checkpoint - 1, data.Total - 2), C.Green)
    elseif data.Event == "fell" then
        toast("Back to your last checkpoint.")
    elseif data.Event == "finish" then
        toast(string.format("Summit! %s%s", data.Text, if data.Improved then " · new best time" else ""), C.Gold)
    elseif data.Event == "rejected" then
        toast("That run was too fast to count. Climb from the start pad.", C.Red)
    end
end)

RunService.RenderStepped:Connect(function()
    if parkour.StartedAt then
        timer.Text = ParkourRules.FormatTime(math.max(0, Workspace:GetServerTimeNow() + parkour.Offset - parkour.StartedAt))
    end
end)

-- Co-op trials ------------------------------------------------------------------------------

local lastCoop = ""

coopState.OnClientEvent:Connect(function(data)
    if data.Event == "finish" then
        toast(string.format("Trials of Brotherhood complete with %d players!", data.Players or 2), C.Gold)
    elseif data.Event == "state" then
        local text = if data.StairsDown then "The stairway is down: climb!" elseif data.LiftUp then "The lift is rising." elseif data.GateOpen then "The gate is open." else ""

        if text ~= "" and text ~= lastCoop then
            toast(text, C.Blue)
        end

        lastCoop = text
    end
end)

-- Sparring ----------------------------------------------------------------------------------

local board = UiKit.Frame(gui, "PvpBoard", UDim2.fromOffset(280, 260), UDim2.new(0, 16, 0, 80))
board.Visible = false
local boardTitle = UiKit.Label(board, "Training Grounds", UDim2.new(1, -20, 0, 22), UDim2.fromOffset(10, 8), 17, true, C.Gold)
local boardBody = UiKit.Label(board, "", UDim2.new(1, -20, 0, 160), UDim2.fromOffset(10, 34), 14)
local boardButtons = Instance.new("Frame")
boardButtons.BackgroundTransparency = 1
boardButtons.Size = UDim2.new(1, -20, 0, 36)
boardButtons.Position = UDim2.new(0, 10, 1, -44)
boardButtons.Parent = board
local boardLayout = Instance.new("UIListLayout")
boardLayout.FillDirection = Enum.FillDirection.Horizontal
boardLayout.Padding = UDim.new(0, 8)
boardLayout.Parent = boardButtons

local pvp = { RoundEndsAt = nil :: number?, CountdownEndsAt = nil :: number?, Phase = "" }

pvpState.OnClientEvent:Connect(function(data)
    board.Visible = data.InMatch == true

    if data.Banner then
        toast(data.Banner, C.Red)
    end

    if not data.InMatch then
        return
    end

    pvp.Phase = data.Phase

    if data.RoundEndsAt then
        pvp.RoundEndsAt = data.RoundEndsAt
    end

    if data.CountdownEndsAt then
        pvp.CountdownEndsAt = data.CountdownEndsAt
    end

    table.sort(data.Players, function(a, b)
        return a.Wins > b.Wins
    end)

    local lines = { string.format("Round %d · first to %d", data.Round, data.RoundsToWin) }

    for _, row in ipairs(data.Players) do
        table.insert(lines, string.format("%s%s  %d wins · %d KOs%s", if row.Alive then "● " else "○ ", data.Names[tostring(row.UserId)] or "Player", row.Wins, row.Knockouts, if row.Rematch then " · ready" else ""))
    end

    boardBody.Text = table.concat(lines, "\n")
    boardTitle.Text = if data.Phase == "Over" then "Match over" else "Training Grounds"
    UiKit.Clear(boardButtons)

    if data.Phase == "Over" then
        UiKit.Button(boardButtons, "Play again", UDim2.fromOffset(124, 34), UDim2.new(), C.Green, function()
            pvpRequest:FireServer("Rematch")
        end)
    end

    UiKit.Button(boardButtons, "Leave", UDim2.fromOffset(124, 34), UDim2.new(), C.PanelLight, function()
        pvpRequest:FireServer("Leave")
    end)
end)

RunService.Heartbeat:Connect(function()
    if not board.Visible then
        return
    end

    local now = Workspace:GetServerTimeNow()

    if pvp.Phase == "Round" and pvp.RoundEndsAt then
        boardTitle.Text = string.format("Round time %ds", math.max(0, math.ceil(pvp.RoundEndsAt - now)))
    elseif pvp.CountdownEndsAt and pvp.CountdownEndsAt > now then
        boardTitle.Text = string.format("Next round in %ds", math.ceil(pvp.CountdownEndsAt - now))
    end
end)

-- Ask for the current state once everything is connected.
campaignRequest:FireServer("State")
parkourRequest:FireServer("State")
