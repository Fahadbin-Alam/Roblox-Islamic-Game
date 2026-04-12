--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HubQuickButtons"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 100
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local function connectButton(button: GuiButton, onClick: () -> ())
    local lastClickAt = 0

    local function runClick()
        local now = os.clock()

        if now - lastClickAt < 0.12 then
            return
        end

        lastClickAt = now
        onClick()
    end

    button.Activated:Connect(runClick)
    button.MouseButton1Click:Connect(runClick)
    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            runClick()
        end
    end)
end

local function createButton(name: string, text: string, yOffset: number, color: Color3): TextButton
    local button = Instance.new("TextButton")
    button.Name = name
    button.AnchorPoint = Vector2.new(0, 1)
    button.Position = UDim2.new(0, 20, 1, yOffset)
    button.Size = UDim2.fromOffset(150, 44)
    button.Active = true
    button.AutoButtonColor = true
    button.BackgroundColor3 = color
    button.Font = Enum.Font.GothamBold
    pcall(function()
        button.Modal = true
    end)
    button.Selectable = true
    button.Text = text
    button.TextColor3 = Color3.fromRGB(250, 246, 234)
    button.TextScaled = true
    button.ZIndex = 20
    button.Parent = screenGui

    local textLimit = Instance.new("UITextSizeConstraint")
    textLimit.MinTextSize = 12
    textLimit.MaxTextSize = 18
    textLimit.Parent = button

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(244, 236, 211)
    stroke.Thickness = 1
    stroke.Transparency = 0.24
    stroke.Parent = button

    return button
end

local itemShopButton = createButton("ItemShopButton", "Item Shop", -144, Color3.fromRGB(73, 97, 61))
local menuButton = createButton("MenuButton", "Menu", -88, Color3.fromRGB(31, 46, 38))
local watchedPanels: { [Frame]: RBXScriptConnection } = {}
local updateAvailability

local function getPanel(guiName: string): Frame?
    local gui = playerGui:FindFirstChild(guiName)

    if not gui then
        return nil
    end

    local panel = gui:FindFirstChild("Panel")

    if panel and panel:IsA("Frame") then
        return panel
    end

    return nil
end

local function setTemporaryText(button: TextButton, text: string)
    local originalText = button.Text
    button.Text = text

    task.delay(0.85, function()
        if button and button.Parent and button.Text == text then
            button.Text = originalText
        end
    end)
end

local function requestFreshShopState()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local shopFolder = remotes and remotes:FindFirstChild("Shop")
    local requestShopState = shopFolder and shopFolder:FindFirstChild("RequestShopState")

    if requestShopState and requestShopState:IsA("RemoteEvent") then
        requestShopState:FireServer()
    end
end

local function openPanel(targetGuiName: string, sourceButton: TextButton)
    local targetPanel = getPanel(targetGuiName)

    if not targetPanel then
        setTemporaryText(sourceButton, "Loading")
        return
    end

    local menuPanel = getPanel("MainMenu")
    local shopPanel = getPanel("ShopMenu")
    local nextVisible = not targetPanel.Visible

    if menuPanel then
        menuPanel.Visible = false
    end

    if shopPanel then
        shopPanel.Visible = false
    end

    targetPanel.Visible = nextVisible

    if targetGuiName == "ShopMenu" and nextVisible then
        requestFreshShopState()
    end

    if updateAvailability then
        updateAvailability()
    end
end

local function anyPanelOpen(): boolean
    local menuPanel = getPanel("MainMenu")
    local shopPanel = getPanel("ShopMenu")

    return (menuPanel and menuPanel.Visible) == true or (shopPanel and shopPanel.Visible) == true
end

local function watchPanel(guiName: string)
    local panel = getPanel(guiName)

    if not panel or watchedPanels[panel] then
        return
    end

    watchedPanels[panel] = panel:GetPropertyChangedSignal("Visible"):Connect(function()
        if updateAvailability then
            updateAvailability()
        end
    end)
end

updateAvailability = function()
    watchPanel("MainMenu")
    watchPanel("ShopMenu")

    local blocked = player:GetAttribute("InBattle") == true or player:GetAttribute("InStory") == true
    local panelOpen = anyPanelOpen()
    itemShopButton.Visible = not blocked and not panelOpen
    menuButton.Visible = not blocked and not panelOpen

    if blocked then
        local menuPanel = getPanel("MainMenu")
        local shopPanel = getPanel("ShopMenu")

        if menuPanel then
            menuPanel.Visible = false
        end

        if shopPanel then
            shopPanel.Visible = false
        end
    end
end

connectButton(itemShopButton, function()
    openPanel("ShopMenu", itemShopButton)
end)

connectButton(menuButton, function()
    openPanel("MainMenu", menuButton)
end)

player:GetAttributeChangedSignal("InBattle"):Connect(updateAvailability)
player:GetAttributeChangedSignal("InStory"):Connect(updateAvailability)
playerGui.ChildAdded:Connect(function(child)
    if child.Name == "MainMenu" or child.Name == "ShopMenu" then
        task.defer(function()
            watchPanel(child.Name)
            updateAvailability()
        end)
    end
end)
updateAvailability()
