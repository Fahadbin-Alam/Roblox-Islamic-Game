--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ContentIndex = require(Shared.Modules.ContentIndex)

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local shopFolder = remotesFolder:WaitForChild("Shop")
local requestShopState = shopFolder:WaitForChild("RequestShopState") :: RemoteEvent
local promptGamePassPurchase = shopFolder:WaitForChild("PromptGamePassPurchase") :: RemoteEvent
local promptDeveloperProductPurchase = shopFolder:WaitForChild("PromptDeveloperProductPurchase") :: RemoteEvent
local equipSkinRemote = shopFolder:WaitForChild("EquipSkin") :: RemoteEvent
local useUltimateRemote = shopFolder:WaitForChild("UseUltimate") :: RemoteEvent
local shopStateEvent = shopFolder:WaitForChild("ShopState") :: RemoteEvent
local purchaseFeedback = shopFolder:WaitForChild("PurchaseFeedback") :: RemoteEvent

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local content = ContentIndex.GetStartupPayload()
local shopCatalog = content.Shop

local state = {
    ownedPasses = {},
    ownedSkins = {},
    equippedSkinId = "default",
    statusText = "Loading shop...",
}

local function arrayToLookup(values)
    local lookup = {}

    for _, value in ipairs(values) do
        lookup[value] = true
    end

    return lookup
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShopMenu"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 64
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.AnchorPoint = Vector2.new(0, 1)
toggleButton.Position = UDim2.new(0, 20, 1, -76)
toggleButton.Size = UDim2.fromOffset(150, 48)
toggleButton.AutoButtonColor = true
toggleButton.BackgroundColor3 = Color3.fromRGB(73, 97, 61)
toggleButton.Text = "Item Shop"
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 18
toggleButton.TextColor3 = Color3.fromRGB(247, 241, 221)
toggleButton.Visible = false
toggleButton.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 12)
toggleCorner.Parent = toggleButton

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -20, 0, 20)
panel.Size = UDim2.fromOffset(370, 560)
panel.BackgroundColor3 = Color3.fromRGB(246, 238, 219)
panel.Visible = false
panel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 18)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(91, 77, 53)
panelStroke.Thickness = 2
panelStroke.Parent = panel

local titleLabel = Instance.new("TextLabel")
titleLabel.BackgroundTransparency = 1
titleLabel.Position = UDim2.fromOffset(18, 16)
titleLabel.Size = UDim2.new(1, -36, 0, 36)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "Item Shop"
titleLabel.TextColor3 = Color3.fromRGB(39, 36, 29)
titleLabel.TextSize = 26
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = panel

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -16, 0, 16)
closeButton.Size = UDim2.fromOffset(40, 34)
closeButton.BackgroundColor3 = Color3.fromRGB(91, 77, 53)
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(250, 245, 232)
closeButton.TextSize = 18
closeButton.Parent = panel

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Position = UDim2.fromOffset(18, 52)
subtitleLabel.Size = UDim2.new(1, -36, 0, 44)
subtitleLabel.Font = Enum.Font.Gotham
subtitleLabel.Text = "Skins, support packs, and extra battle charges."
subtitleLabel.TextColor3 = Color3.fromRGB(78, 70, 56)
subtitleLabel.TextSize = 14
subtitleLabel.TextWrapped = true
subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
subtitleLabel.TextYAlignment = Enum.TextYAlignment.Top
subtitleLabel.Parent = panel

local statLabel = Instance.new("TextLabel")
statLabel.BackgroundTransparency = 1
statLabel.Position = UDim2.fromOffset(18, 100)
statLabel.Size = UDim2.new(1, -36, 0, 24)
statLabel.Font = Enum.Font.GothamBold
statLabel.Text = "Knowledge Tokens: 0 | Ultimate Charges: 0"
statLabel.TextColor3 = Color3.fromRGB(58, 89, 66)
statLabel.TextSize = 15
statLabel.TextXAlignment = Enum.TextXAlignment.Left
statLabel.Parent = panel

local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Name = "Catalog"
scrollingFrame.Position = UDim2.fromOffset(14, 136)
scrollingFrame.Size = UDim2.new(1, -28, 1, -196)
scrollingFrame.BackgroundTransparency = 1
scrollingFrame.BorderSizePixel = 0
scrollingFrame.CanvasSize = UDim2.zero
scrollingFrame.ScrollBarThickness = 6
scrollingFrame.Parent = panel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 10)
listLayout.Parent = scrollingFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.new(0, 18, 1, -50)
statusLabel.Size = UDim2.new(1, -36, 0, 30)
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.Text = state.statusText
statusLabel.TextColor3 = Color3.fromRGB(74, 91, 68)
statusLabel.TextSize = 14
statusLabel.TextWrapped = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = panel

local ultimatePanel = Instance.new("Frame")
ultimatePanel.Name = "UltimatePanel"
ultimatePanel.AnchorPoint = Vector2.new(1, 1)
ultimatePanel.Position = UDim2.new(1, -20, 1, -20)
ultimatePanel.Size = UDim2.fromOffset(240, 92)
ultimatePanel.BackgroundColor3 = Color3.fromRGB(43, 49, 38)
ultimatePanel.Visible = false
ultimatePanel.Parent = screenGui

local ultimateCorner = Instance.new("UICorner")
ultimateCorner.CornerRadius = UDim.new(0, 14)
ultimateCorner.Parent = ultimatePanel

local ultimateTitle = Instance.new("TextLabel")
ultimateTitle.BackgroundTransparency = 1
ultimateTitle.Position = UDim2.fromOffset(14, 10)
ultimateTitle.Size = UDim2.new(1, -28, 0, 22)
ultimateTitle.Font = Enum.Font.GothamBold
ultimateTitle.Text = "Battle Ultimate"
ultimateTitle.TextColor3 = Color3.fromRGB(244, 233, 210)
ultimateTitle.TextSize = 18
ultimateTitle.TextXAlignment = Enum.TextXAlignment.Left
ultimateTitle.Parent = ultimatePanel

local ultimateCount = Instance.new("TextLabel")
ultimateCount.BackgroundTransparency = 1
ultimateCount.Position = UDim2.fromOffset(14, 36)
ultimateCount.Size = UDim2.new(1, -120, 0, 20)
ultimateCount.Font = Enum.Font.Gotham
ultimateCount.Text = "Charges: 0"
ultimateCount.TextColor3 = Color3.fromRGB(213, 220, 197)
ultimateCount.TextSize = 14
ultimateCount.TextXAlignment = Enum.TextXAlignment.Left
ultimateCount.Parent = ultimatePanel

local ultimateHint = Instance.new("TextLabel")
ultimateHint.BackgroundTransparency = 1
ultimateHint.Position = UDim2.fromOffset(14, 56)
ultimateHint.Size = UDim2.new(1, -120, 0, 24)
ultimateHint.Font = Enum.Font.Gotham
ultimateHint.Text = "A gold shockwave that hits nearby enemies."
ultimateHint.TextColor3 = Color3.fromRGB(192, 198, 180)
ultimateHint.TextSize = 12
ultimateHint.TextWrapped = true
ultimateHint.TextXAlignment = Enum.TextXAlignment.Left
ultimateHint.TextYAlignment = Enum.TextYAlignment.Top
ultimateHint.Parent = ultimatePanel

local ultimateButton = Instance.new("TextButton")
ultimateButton.AnchorPoint = Vector2.new(1, 0.5)
ultimateButton.Position = UDim2.new(1, -12, 0.5, 8)
ultimateButton.Size = UDim2.fromOffset(92, 40)
ultimateButton.BackgroundColor3 = Color3.fromRGB(180, 149, 78)
ultimateButton.Font = Enum.Font.GothamBold
ultimateButton.Text = "Use"
ultimateButton.TextColor3 = Color3.fromRGB(255, 249, 237)
ultimateButton.TextSize = 18
ultimateButton.Parent = ultimatePanel

local ultimateButtonCorner = Instance.new("UICorner")
ultimateButtonCorner.CornerRadius = UDim.new(0, 10)
ultimateButtonCorner.Parent = ultimateButton

local function createSectionTitle(text: string)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -10, 0, 26)
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = Color3.fromRGB(52, 49, 43)
    label.TextSize = 18
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = scrollingFrame
end

local function createCard(title: string, subtitle: string, buttonText: string, buttonColor: Color3, onClick)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -10, 0, 104)
    card.BackgroundColor3 = Color3.fromRGB(255, 250, 239)
    card.Parent = scrollingFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(189, 175, 145)
    stroke.Thickness = 1.2
    stroke.Parent = card

    local titleLabelInner = Instance.new("TextLabel")
    titleLabelInner.BackgroundTransparency = 1
    titleLabelInner.Position = UDim2.fromOffset(14, 12)
    titleLabelInner.Size = UDim2.new(1, -108, 0, 22)
    titleLabelInner.Font = Enum.Font.GothamBold
    titleLabelInner.Text = title
    titleLabelInner.TextColor3 = Color3.fromRGB(40, 37, 31)
    titleLabelInner.TextSize = 16
    titleLabelInner.TextXAlignment = Enum.TextXAlignment.Left
    titleLabelInner.Parent = card

    local subtitleLabelInner = Instance.new("TextLabel")
    subtitleLabelInner.BackgroundTransparency = 1
    subtitleLabelInner.Position = UDim2.fromOffset(14, 38)
    subtitleLabelInner.Size = UDim2.new(1, -128, 0, 54)
    subtitleLabelInner.Font = Enum.Font.Gotham
    subtitleLabelInner.Text = subtitle
    subtitleLabelInner.TextColor3 = Color3.fromRGB(86, 78, 64)
    subtitleLabelInner.TextSize = 13
    subtitleLabelInner.TextWrapped = true
    subtitleLabelInner.TextXAlignment = Enum.TextXAlignment.Left
    subtitleLabelInner.TextYAlignment = Enum.TextYAlignment.Top
    subtitleLabelInner.Parent = card

    local button = Instance.new("TextButton")
    button.AnchorPoint = Vector2.new(1, 0.5)
    button.Position = UDim2.new(1, -12, 0.5, 0)
    button.Size = UDim2.fromOffset(86, 34)
    button.BackgroundColor3 = buttonColor
    button.Font = Enum.Font.GothamBold
    button.Text = buttonText
    button.TextColor3 = Color3.fromRGB(250, 246, 236)
    button.TextSize = 15
    button.Parent = card

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 10)
    buttonCorner.Parent = button

    button.MouseButton1Click:Connect(onClick)
end

local function rebuildCatalog()
    for _, child in ipairs(scrollingFrame:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end

    local ultimateCharges = player:GetAttribute("UltimateCharges") or 0
    local knowledgeTokens = player:GetAttribute("KnowledgeTokens") or 0
    statLabel.Text = string.format("Knowledge Tokens: %d | Ultimate Charges: %d", knowledgeTokens, ultimateCharges)

    createSectionTitle("Support & Passes")

    for _, item in ipairs(shopCatalog.GamePasses) do
        local owned = state.ownedPasses[item.Key] == true
        local buttonText = owned and "Owned" or "Buy"
        local buttonColor = owned and Color3.fromRGB(74, 118, 76) or Color3.fromRGB(126, 94, 57)

        createCard(item.DisplayName, item.Benefit, buttonText, buttonColor, function()
            if not owned then
                promptGamePassPurchase:FireServer(item.Key)
            end
        end)
    end

    createSectionTitle("Battle Products")

    for _, item in ipairs(shopCatalog.DeveloperProducts) do
        createCard(item.DisplayName, item.Benefit, "Buy", Color3.fromRGB(96, 84, 133), function()
            promptDeveloperProductPurchase:FireServer(item.Key)
        end)
    end

    createSectionTitle("Skins")

    for skinId, skinDefinition in pairs(shopCatalog.SkinDefinitions) do
        local owned = state.ownedSkins[skinId] == true
        local equipped = state.equippedSkinId == skinId
        local buttonText = equipped and "Equipped" or (owned and "Equip" or "Locked")
        local buttonColor = equipped and Color3.fromRGB(70, 122, 78) or (owned and Color3.fromRGB(110, 118, 64) or Color3.fromRGB(138, 131, 121))
        local unlockText = "Included by default."

        if skinDefinition.UnlockType == "GamePass" then
            unlockText = owned and "Unlocked from the shop." or "Unlock this skin through its matching pass above."
        end

        createCard(skinDefinition.DisplayName, unlockText, buttonText, buttonColor, function()
            if owned and not equipped then
                equipSkinRemote:FireServer(skinId)
            end
        end)
    end

    createSectionTitle("Ad Revenue Setup")
    createCard(
        shopCatalog.RewardedAds.DisplayName,
        shopCatalog.RewardedAds.Benefit .. " " .. shopCatalog.RewardedAds.Disclosure,
        "Ad-Ready",
        Color3.fromRGB(70, 103, 122),
        function()
            statusLabel.Text = "Rewarded ads need Creator Hub setup, eligibility, and a real placement ID."
        end
    )

    createSectionTitle("Store Rules")

    for _, rule in ipairs(shopCatalog.Rules) do
        local ruleLabel = Instance.new("TextLabel")
        ruleLabel.BackgroundTransparency = 1
        ruleLabel.Size = UDim2.new(1, -12, 0, 42)
        ruleLabel.Font = Enum.Font.Gotham
        ruleLabel.Text = "- " .. rule
        ruleLabel.TextColor3 = Color3.fromRGB(86, 78, 64)
        ruleLabel.TextSize = 13
        ruleLabel.TextWrapped = true
        ruleLabel.TextXAlignment = Enum.TextXAlignment.Left
        ruleLabel.TextYAlignment = Enum.TextYAlignment.Top
        ruleLabel.Parent = scrollingFrame
    end

    statusLabel.Text = state.statusText
end

local function updateCanvas()
    scrollingFrame.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + 10)
end

local function updateUltimatePanel()
    local charges = player:GetAttribute("UltimateCharges") or 0
    local inBattle = player:GetAttribute("InBattle") == true

    ultimatePanel.Visible = inBattle
    ultimateCount.Text = string.format("Charges: %d", charges)
    ultimateButton.Text = charges > 0 and "Use" or "Buy More"
end

shopStateEvent.OnClientEvent:Connect(function(payload)
    state.ownedPasses = arrayToLookup(payload.OwnedPassKeys or {})
    state.ownedSkins = arrayToLookup(payload.OwnedSkinIds or {})
    state.equippedSkinId = payload.EquippedSkinId or "default"

    if type(payload.StatusText) == "string" and payload.StatusText ~= "" then
        state.statusText = payload.StatusText
    end

    rebuildCatalog()
    updateCanvas()
    updateUltimatePanel()
end)

purchaseFeedback.OnClientEvent:Connect(function(payload)
    if typeof(payload) == "table" and type(payload.Text) == "string" then
        state.statusText = payload.Text
        statusLabel.Text = payload.Text
    end
end)

toggleButton.MouseButton1Click:Connect(function()
    panel.Visible = not panel.Visible

    if panel.Visible then
        requestShopState:FireServer()
    end
end)

closeButton.MouseButton1Click:Connect(function()
    panel.Visible = false
end)

ultimateButton.MouseButton1Click:Connect(function()
    if (player:GetAttribute("UltimateCharges") or 0) > 0 then
        useUltimateRemote:FireServer()
    else
        promptDeveloperProductPurchase:FireServer("ultimate_charge_single")
    end
end)

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
player:GetAttributeChangedSignal("UltimateCharges"):Connect(function()
    rebuildCatalog()
    updateCanvas()
    updateUltimatePanel()
end)
player:GetAttributeChangedSignal("KnowledgeTokens"):Connect(function()
    rebuildCatalog()
    updateCanvas()
end)
player:GetAttributeChangedSignal("InBattle"):Connect(updateUltimatePanel)

local function updateToggleAvailability()
    local inStory = player:GetAttribute("InStory") == true
    local inBattle = player:GetAttribute("InBattle") == true

    toggleButton.Visible = false

    if inStory or inBattle then
        panel.Visible = false
    end
end

player:GetAttributeChangedSignal("InStory"):Connect(updateToggleAvailability)
player:GetAttributeChangedSignal("InBattle"):Connect(updateToggleAvailability)

rebuildCatalog()
updateCanvas()
updateUltimatePanel()
updateToggleAvailability()
requestShopState:FireServer()
