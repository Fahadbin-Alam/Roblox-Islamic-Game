--!strict

-- Shows each player's level and rank title above their head in the hub, so friends can see
-- how far everyone has come. The tag hides during battles and stories.

local Players = game:GetService("Players")

local TAG_NAME = "RankTag"

local function tagText(player: Player): string?
    local level = player:GetAttribute("Level")
    local title = player:GetAttribute("RankTitle")

    if type(level) ~= "number" then
        return nil
    end

    return string.format("Level %d  ·  %s", level, if type(title) == "string" then title else "Seeker")
end

local function refresh(player: Player)
    local character = player.Character
    local head = character and character:FindFirstChild("Head")

    if not head or not head:IsA("BasePart") then
        return
    end

    local text = tagText(player)
    local billboard = head:FindFirstChild(TAG_NAME)

    if not text then
        if billboard then
            billboard:Destroy()
        end

        return
    end

    if not billboard or not billboard:IsA("BillboardGui") then
        local newBillboard = Instance.new("BillboardGui")
        newBillboard.Name = TAG_NAME
        newBillboard.Size = UDim2.fromOffset(200, 24)
        -- Sits above the Roblox name tag.
        newBillboard.StudsOffset = Vector3.new(0, 3.4, 0)
        newBillboard.MaxDistance = 60
        newBillboard.Parent = head

        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "Text"
        textLabel.BackgroundTransparency = 1
        textLabel.Size = UDim2.fromScale(1, 1)
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextColor3 = Color3.fromRGB(240, 207, 120)
        textLabel.TextStrokeTransparency = 0.45
        textLabel.TextSize = 15
        textLabel.Parent = newBillboard

        billboard = newBillboard
    end

    local gui = billboard :: BillboardGui
    local textLabel = gui:FindFirstChild("Text")

    if textLabel and textLabel:IsA("TextLabel") then
        textLabel.Text = text
    end

    gui.Enabled = player:GetAttribute("InBattle") ~= true and player:GetAttribute("InStory") ~= true
end

local function onPlayerAdded(player: Player)
    player.CharacterAdded:Connect(function(character)
        character:WaitForChild("Head", 10)
        refresh(player)
    end)

    for _, attribute in ipairs({ "Level", "RankTitle", "InBattle", "InStory" }) do
        player:GetAttributeChangedSignal(attribute):Connect(function()
            refresh(player)
        end)
    end

    if player.Character then
        task.spawn(refresh, player)
    end
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(onPlayerAdded, player)
end
