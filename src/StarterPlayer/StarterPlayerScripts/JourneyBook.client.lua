--!strict

-- The Journeys book: one panel for the Seerah campaign checklist, the Sahabi mysteries, the
-- activities (parkour, co-op, sparring, historical zones), friends and safety tools, and
-- optional support. Opened from the "Journeys" button (HubQuickButtons).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local StarterGui = game:GetService("StarterGui")

local UiKit = require(script.Parent:WaitForChild("UiKit"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SahabiMysteries = require(Shared.Data.SahabiMysteries)
local ParkourRules = require(Shared.Modules.ParkourRules)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local function remote(folder: string, name: string): RemoteEvent
    return remotes:WaitForChild(folder):WaitForChild(name) :: RemoteEvent
end

local campaignRequest, campaignState = remote("Campaign", "Request"), remote("Campaign", "State")
local mysteryRequest = remote("Mystery", "Request")
local pvpRequest = remote("Pvp", "Request")
local socialRequest, socialState = remote("Social", "Request"), remote("Social", "State")
local supportRequest, supportState = remote("Support", "Request"), remote("Support", "State")
local teleportRequest = remote("Hub", "RequestTeleport")
local profileUpdated = remote("Progress", "ProfileUpdated")

local C = UiKit.Colors

local gui = Instance.new("ScreenGui")
gui.Name = "JourneyBook"
gui.ResetOnSpawn = false
gui.DisplayOrder = 110
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local panel = UiKit.Frame(gui, "Panel", UDim2.fromOffset(780, 520), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
panel.Visible = false

UiKit.Label(panel, "Journeys", UDim2.new(1, -80, 0, 34), UDim2.fromOffset(18, 12), 26, true, C.Gold)
UiKit.Button(panel, "X", UDim2.fromOffset(40, 36), UDim2.new(1, -52, 0, 10), C.Red, function()
    panel.Visible = false
end)

local tabBar = Instance.new("Frame")
tabBar.BackgroundTransparency = 1
tabBar.Size = UDim2.new(1, -36, 0, 40)
tabBar.Position = UDim2.fromOffset(18, 52)
tabBar.Parent = panel

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 8)
tabLayout.Parent = tabBar

local content = UiKit.Scroller(panel, UDim2.new(1, -36, 1, -112), UDim2.fromOffset(18, 100))

local state = {
    Tab = "Seerah",
    Campaign = nil :: any,
    Profile = nil :: any,
    Support = nil :: any,
    Voice = {} :: { [string]: boolean },
    Muted = {} :: { [number]: boolean },
    Message = "",
}

local render: () -> ()

local function close()
    panel.Visible = false
end

local function teleport(destinationId: string)
    teleportRequest:FireServer(destinationId)
    close()
end

local function completedSet(category: string): { [string]: boolean }
    local set = {}
    local profile = state.Profile

    if profile and profile.Completed and profile.Completed[category] then
        for _, id in ipairs(profile.Completed[category]) do
            set[id] = true
        end
    end

    return set
end

-- Tabs ---------------------------------------------------------------------------------------

local tabs = {}

function tabs.Seerah()
    local data = state.Campaign

    if not data then
        UiKit.Paragraph(content, "Loading the campaign...", 16)
        return
    end

    UiKit.Paragraph(content, string.format("<b>The Seerah campaign</b>: %d of %d chapters complete. Chapters open in order. The Prophet ﷺ is never shown or voiced: his life is told in written narration only, in historical reconstructions of Makkah and Madinah.", data.DoneCount, data.Total), 15)

    local era = ""

    for index, entry in ipairs(data.Checklist) do
        if entry.Era ~= era then
            era = entry.Era
            local heading = UiKit.Paragraph(content, if era == "Makkah" then "The Makkan years" else "The Madinan years", 18, true, C.Gold)
            heading.LayoutOrder = index * 2 - 1
        end

        local status = if entry.Done then "Done" elseif entry.Unlocked then "Open" else "Locked"
        local buttons = {}

        if entry.Unlocked then
            table.insert(buttons, {
                Text = if entry.Done then "Replay" else "Start",
                Color = if entry.Done then C.Blue else C.Green,
                OnClick = function()
                    campaignRequest:FireServer("Start", entry.Id)
                    close()
                end,
            })
        end

        local row = UiKit.Row(content, index * 2, string.format("%s  %d. %s", if entry.Done then "✓" elseif entry.Unlocked then "▶" else "🔒", entry.Number, entry.Title), string.format("%s  ·  %s", entry.When, status), buttons)
        row.LayoutOrder = index * 2
    end
end

function tabs.Mysteries()
    local solved = completedSet("mystery")
    local stats = (state.Profile and state.Profile.Stats) or {}

    UiKit.Paragraph(content, "<b>Sahabi Mystery Rooms</b>: escape-room puzzles about the companions. Friends in the same room share clues. Clue objects are game props; every room ends with the documented story and its sources.", 15)

    for index, mystery in ipairs(SahabiMysteries.Mysteries) do
        local stars = stats["MysteryStars_" .. mystery.Id] or 0
        local status = if solved[mystery.Id] then string.format("Solved  %s", string.rep("★", stars) .. string.rep("☆", 3 - stars)) else "Not solved yet"
        UiKit.Row(content, index, mystery.Title, string.format("%s  ·  %s", mystery.Tagline, status), {
            {
                Text = "Go",
                Color = C.Purple,
                OnClick = function()
                    mysteryRequest:FireServer("Teleport", mystery.Id)
                    close()
                end,
            },
        })
    end
end

function tabs.Activities()
    local stats = (state.Profile and state.Profile.Stats) or {}
    local best = stats.ParkourBest_lobby_tower
    local rows = {
        { "Old Makkah (historical)", "Seerah reconstruction of Makkah, c. 570-630 CE. Not today's city.", "seerah_campaign" },
        { "Old Madinah (historical)", "Seerah reconstruction of Madinah, c. 622-632 CE. Not today's city.", "seerah_madinah" },
        { "Masjid al-Haram (today)", "Present-day Makkah: explore today's mosque around the Kaaba.", "kaaba_courtyard" },
        { "Prophet's Mosque (today)", "Present-day Madinah: the courtyard of today's Masjid an-Nabawi.", "medina_courtyard" },
        { "Lobby Parkour Tower", if best and best > 0 then "Your best time: " .. ParkourRules.FormatTime(best) else "Timed climb with checkpoints. No best time yet.", "parkour_tower" },
        { "Trials of Brotherhood", "Two-player co-op puzzles. Bring a friend.", "coop_trials" },
        { "Training Grounds", "PvP sparring for 2-8 players, first to 3 rounds.", "training_grounds" },
        { "Badr and Uhud gates", "Story Missions and Team Skirmish.", "badr_gate" },
    }

    for index, entry in ipairs(rows) do
        local buttons = {
            {
                Text = "Go",
                OnClick = function()
                    teleport(entry[3])
                end,
            },
        }

        if entry[3] == "training_grounds" then
            table.insert(buttons, {
                Text = "Join match",
                Color = C.Red,
                OnClick = function()
                    pvpRequest:FireServer("Teleport")
                    task.delay(0.6, function()
                        pvpRequest:FireServer("Join")
                    end)
                    close()
                end,
            })
        end

        UiKit.Row(content, index, entry[1], entry[2], buttons)
    end
end

local function inviteFriends()
    local ok, canInvite = pcall(function()
        return SocialService:CanSendGameInviteAsync(player)
    end)

    if ok and canInvite then
        pcall(function()
            SocialService:PromptGameInvite(player)
        end)
    else
        state.Message = "Invites aren't available on this account or device. Friends can still join you from the Roblox app."
        render()
    end
end

function tabs.Friends()
    UiKit.Paragraph(content, "<b>Play together</b>: invite friends, jump to a friend's activity, and keep chat friendly. Voice chat is Roblox's own: it works only for eligible players (13+ and verified) who turned it on. Mute, block, and report always work.", 15)

    if state.Message ~= "" then
        UiKit.Paragraph(content, state.Message, 14, true, C.Gold)
    end

    UiKit.Row(content, 1, "Invite friends", "Send a Roblox invite to friends so they can join this server.", {
        { Text = "Invite", OnClick = inviteFriends },
    })

    local order = 2

    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player then
            local muted = state.Muted[other.UserId] == true
            local voice = state.Voice[tostring(other.UserId)]
            local body = string.format("@%s%s", other.Name, if voice then "  ·  voice on" else "")
            local row = UiKit.Row(content, order, other.DisplayName, body, {
                {
                    Text = "Join",
                    Color = C.Blue,
                    OnClick = function()
                        socialRequest:FireServer("JumpTo", other.UserId)
                        close()
                    end,
                },
                {
                    Text = if muted then "Unmute" else "Mute",
                    Color = C.PanelLight,
                    OnClick = function()
                        socialRequest:FireServer("Mute", { UserId = other.UserId, Muted = not muted })
                    end,
                },
            })

            -- Block and report sit on a second line so they are never pressed by accident.
            row.Size = UDim2.new(1, 0, 0, 110)
            UiKit.Button(row, "Block", UDim2.fromOffset(108, 36), UDim2.new(1, -232, 0, 64), C.Red, function()
                pcall(function()
                    StarterGui:SetCore("PromptBlockPlayer", other)
                end)
            end)
            UiKit.Button(row, "Report", UDim2.fromOffset(108, 36), UDim2.new(1, -116, 0, 64), C.Red, function()
                state.Message = string.format("To report %s: open the Roblox menu (Esc, or the Roblox logo at the top left), choose Report, and pick them from the list. Reports go straight to Roblox.", other.DisplayName)
                render()
            end)
            order += 1
        end
    end

    if order == 2 then
        UiKit.Paragraph(content, "Nobody else is in this server yet. Invite a friend!", 15, false, C.Muted)
    end
end

function tabs.Support()
    local data = state.Support or {}

    UiKit.Paragraph(content, "<b>Support the game</b>: everything here is optional. No lesson, chapter, or mission is ever locked behind an ad or a purchase.", 15)

    if data.Message then
        UiKit.Paragraph(content, data.Message, 14, true, C.Gold)
    end

    local adBody = if data.AdsConfigured == false
        then "Rewarded videos are not set up for this game yet."
        else string.format("Watch a short video for +%d Knowledge Tokens. %d left today. Roblox only shows ads to eligible players.", data.RewardTokens or 0, data.AdsLeftToday or 0)

    UiKit.Row(content, 1, "Watch a video", adBody, {
        {
            Text = "Watch",
            OnClick = function()
                supportRequest:FireServer("WatchAd")
            end,
        },
    })

    UiKit.Row(content, 2, "Item Shop", "Cosmetic outfits and support packs.", {
        {
            Text = "Open",
            Color = C.Blue,
            OnClick = function()
                close()
                local shop = playerGui:FindFirstChild("ShopMenu")
                local shopPanel = shop and shop:FindFirstChild("Panel")

                if shopPanel and shopPanel:IsA("GuiObject") then
                    shopPanel.Visible = true
                end
            end,
        },
    })

    if data.IsCreator then
        UiKit.Row(content, 3, "Creator numbers (last 14 days)", "Revenue, ads, joins, and returns recorded by this game. Creator Hub has the official totals.", {
            {
                Text = "Load",
                Color = C.Purple,
                OnClick = function()
                    supportRequest:FireServer("Ledger")
                end,
            },
        })

        if data.Ledger then
            local lines = { "<b>Day (UTC)  Robux  Purchases  Ads  Joins  New  D1  D7  Minutes</b>" }

            for _, row in ipairs(data.Ledger) do
                local d = row.Data
                table.insert(lines, string.format("%s  %d  %d  %d  %d  %d  %d  %d  %d", os.date("!%Y-%m-%d", row.Day * 86400), d.RobuxSpent or 0, d.Purchases or 0, d.AdRewards or 0, d.Joins or 0, d.NewPlayers or 0, d.D1Returns or 0, d.D7Returns or 0, d.SessionMinutes or 0))
            end

            local costs = data.Costs or {}
            local monthly = (costs.SponsoredAds or 0) + (costs.AssetUploads or 0) + (costs.Other or 0)
            local taken = 0

            for _, row in ipairs(data.Ledger) do
                taken += row.Data.RobuxSpent or 0
            end

            local periodCosts = math.floor(monthly * #data.Ledger / 30 + 0.5)
            table.insert(lines, string.format("Robux spent by players over these %d days: %d. Costs for the same days: %d (from %d a month in MonetizationConfig). Before the Roblox fee: %d.", #data.Ledger, taken, periodCosts, monthly, taken - periodCosts))
            local label = UiKit.Paragraph(content, table.concat(lines, "\n"), 13)
            label.LayoutOrder = 4
            label.Font = Enum.Font.Code
        end
    end
end

local TAB_ORDER = { "Seerah", "Mysteries", "Activities", "Friends", "Support" }

for _, name in ipairs(TAB_ORDER) do
    UiKit.Button(tabBar, name, UDim2.fromOffset(136, 36), UDim2.new(), C.PanelLight, function()
        state.Tab = name

        if name == "Friends" then
            state.Message = ""
            socialRequest:FireServer("Voice")
        elseif name == "Support" then
            supportRequest:FireServer("State")
        end

        render()
    end)
end

render = function()
    UiKit.Clear(content)

    for _, button in ipairs(tabBar:GetChildren()) do
        if button:IsA("TextButton") then
            button.BackgroundColor3 = if button.Text == state.Tab then C.Gold else C.PanelLight
            button.TextColor3 = if button.Text == state.Tab then Color3.fromRGB(30, 30, 24) else C.Text
        end
    end

    local ok, err = pcall(tabs[state.Tab])

    if not ok then
        warn("[JourneyBook] " .. tostring(err))
    end
end

campaignState.OnClientEvent:Connect(function(data)
    state.Campaign = data

    if panel.Visible and state.Tab == "Seerah" then
        render()
    end
end)

profileUpdated.OnClientEvent:Connect(function(snapshot)
    state.Profile = snapshot

    if panel.Visible and state.Tab ~= "Seerah" and state.Tab ~= "Friends" then
        render()
    end
end)

socialState.OnClientEvent:Connect(function(data)
    if data.Voice then
        state.Voice = data.Voice
    end

    if data.Muted then
        state.Muted[data.Muted.UserId] = data.Muted.Muted
    end

    if data.Message then
        state.Message = data.Message
    end

    if panel.Visible and state.Tab == "Friends" then
        render()
    end
end)

supportState.OnClientEvent:Connect(function(data)
    local previous = state.Support or {}

    if data.Ledger == nil then
        data.Ledger = previous.Ledger
        data.Costs = previous.Costs
    end

    state.Support = data

    if panel.Visible and state.Tab == "Support" then
        render()
    end
end)

panel:GetPropertyChangedSignal("Visible"):Connect(function()
    if panel.Visible then
        campaignRequest:FireServer("State")
        render()
    end
end)

Players.PlayerAdded:Connect(function()
    if panel.Visible and state.Tab == "Friends" then
        render()
    end
end)

Players.PlayerRemoving:Connect(function()
    if panel.Visible and state.Tab == "Friends" then
        task.defer(render)
    end
end)

campaignRequest:FireServer("State")
