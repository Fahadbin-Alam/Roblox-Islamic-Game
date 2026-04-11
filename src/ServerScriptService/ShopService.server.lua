--!strict

local DataStoreService = game:GetService("DataStoreService")
local Debris = game:GetService("Debris")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ShopCatalog = require(Shared.Data.ShopCatalog)
local BattleLoadout = require(script.Parent.Modules.BattleLoadout)

local shopFolder = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Shop")
local requestShopState = shopFolder:WaitForChild("RequestShopState") :: RemoteEvent
local promptGamePassPurchase = shopFolder:WaitForChild("PromptGamePassPurchase") :: RemoteEvent
local promptDeveloperProductPurchase = shopFolder:WaitForChild("PromptDeveloperProductPurchase") :: RemoteEvent
local equipSkin = shopFolder:WaitForChild("EquipSkin") :: RemoteEvent
local useUltimate = shopFolder:WaitForChild("UseUltimate") :: RemoteEvent
local shopStateEvent = shopFolder:WaitForChild("ShopState") :: RemoteEvent
local purchaseFeedback = shopFolder:WaitForChild("PurchaseFeedback") :: RemoteEvent
local grantCurrency = shopFolder:FindFirstChild("GrantCurrency")

if not grantCurrency then
    local bindable = Instance.new("BindableEvent")
    bindable.Name = "GrantCurrency"
    bindable.Parent = shopFolder
    grantCurrency = bindable
end

local profileStore = DataStoreService:GetDataStore("PlayerMonetization_v1")
local receiptStore = DataStoreService:GetDataStore("ProcessedReceipts_v1")

local playerProfiles: { [Player]: { EquippedSkin: string, UltimateCharges: number, KnowledgeTokens: number, SupportPoints: number } } = {}
local playerPassOwnership: { [Player]: { [string]: boolean } } = {}
local ultimateCooldowns: { [Player]: number } = {}

local gamePassByKey = {}
local gamePassByProductId = {}
local developerProductByKey = {}
local developerProductByProductId = {}

for _, item in ipairs(ShopCatalog.GamePasses) do
    gamePassByKey[item.Key] = item

    if item.ProductId > 0 then
        gamePassByProductId[item.ProductId] = item
    end
end

for _, item in ipairs(ShopCatalog.DeveloperProducts) do
    developerProductByKey[item.Key] = item

    if item.ProductId > 0 then
        developerProductByProductId[item.ProductId] = item
    end
end

local function buildDefaultProfile()
    return {
        EquippedSkin = "default",
        UltimateCharges = 0,
        KnowledgeTokens = 0,
        SupportPoints = 0,
    }
end

local function cloneProfile(source)
    return {
        EquippedSkin = source.EquippedSkin,
        UltimateCharges = source.UltimateCharges,
        KnowledgeTokens = source.KnowledgeTokens,
        SupportPoints = source.SupportPoints,
    }
end

local function sendFeedback(player: Player, text: string, tone: string?)
    purchaseFeedback:FireClient(player, {
        Text = text,
        Tone = tone or "info",
    })
end

local function getOwnedSkins(ownedPasses: { [string]: boolean }): { [string]: boolean }
    local ownedSkins = {
        default = true,
    }

    for skinId, skinDefinition in pairs(ShopCatalog.SkinDefinitions) do
        if skinDefinition.UnlockType == "GamePass" and ownedPasses[skinDefinition.UnlockKey] then
            ownedSkins[skinId] = true
        end
    end

    return ownedSkins
end

local function sanitizeEquippedSkin(profile, ownedPasses: { [string]: boolean })
    local ownedSkins = getOwnedSkins(ownedPasses)

    if not ownedSkins[profile.EquippedSkin] then
        profile.EquippedSkin = "default"
    end
end

local function applyPlayerAttributes(player: Player)
    local profile = playerProfiles[player] or buildDefaultProfile()
    local ownedPasses = playerPassOwnership[player] or {}

    sanitizeEquippedSkin(profile, ownedPasses)
    playerProfiles[player] = profile

    player:SetAttribute("EquippedBattleSkin", profile.EquippedSkin)
    player:SetAttribute("UltimateCharges", profile.UltimateCharges)
    player:SetAttribute("KnowledgeTokens", profile.KnowledgeTokens)
    player:SetAttribute("SupportPoints", profile.SupportPoints)
    player:SetAttribute("HasFounderSupport", ownedPasses.founder_support == true)
end

local function saveProfile(player: Player)
    local profile = playerProfiles[player]

    if not profile then
        return
    end

    local profileCopy = cloneProfile(profile)

    task.spawn(function()
        local success, errorMessage = pcall(function()
            profileStore:SetAsync(string.format("player_%d", player.UserId), profileCopy)
        end)

        if not success then
            warn(string.format("[ShopService] Failed to save profile for %s: %s", player.Name, tostring(errorMessage)))
        end
    end)
end

local function refreshPassOwnership(player: Player)
    local ownedPasses = {}

    for _, item in ipairs(ShopCatalog.GamePasses) do
        local owned = false

        if item.ProductId > 0 then
            local success, result = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(player.UserId, item.ProductId)
            end)

            if success then
                owned = result
            end
        end

        ownedPasses[item.Key] = owned
    end

    playerPassOwnership[player] = ownedPasses
    applyPlayerAttributes(player)
end

local function listOwnedKeys(lookup: { [string]: boolean }): { string }
    local results = {}

    for key, isOwned in pairs(lookup) do
        if isOwned then
            table.insert(results, key)
        end
    end

    table.sort(results)

    return results
end

local function sendShopState(player: Player, statusText: string?)
    local profile = playerProfiles[player] or buildDefaultProfile()
    local ownedPasses = playerPassOwnership[player] or {}
    local ownedSkins = getOwnedSkins(ownedPasses)

    shopStateEvent:FireClient(player, {
        OwnedPassKeys = listOwnedKeys(ownedPasses),
        OwnedSkinIds = listOwnedKeys(ownedSkins),
        EquippedSkinId = profile.EquippedSkin,
        UltimateCharges = profile.UltimateCharges,
        KnowledgeTokens = profile.KnowledgeTokens,
        SupportPoints = profile.SupportPoints,
        StatusText = statusText or "",
    })
end

local function loadProfile(player: Player)
    local profile = buildDefaultProfile()

    local success, storedProfile = pcall(function()
        return profileStore:GetAsync(string.format("player_%d", player.UserId))
    end)

    if success and type(storedProfile) == "table" then
        if type(storedProfile.EquippedSkin) == "string" then
            profile.EquippedSkin = storedProfile.EquippedSkin
        end

        if type(storedProfile.UltimateCharges) == "number" then
            profile.UltimateCharges = storedProfile.UltimateCharges
        end

        if type(storedProfile.KnowledgeTokens) == "number" then
            profile.KnowledgeTokens = storedProfile.KnowledgeTokens
        end

        if type(storedProfile.SupportPoints) == "number" then
            profile.SupportPoints = storedProfile.SupportPoints
        end
    elseif not success then
        warn(string.format("[ShopService] Failed to load profile for %s: %s", player.Name, tostring(storedProfile)))
    end

    playerProfiles[player] = profile
    refreshPassOwnership(player)
    sendShopState(player, "Shop ready.")
end

local function grantDeveloperProduct(player: Player, product)
    local profile = playerProfiles[player]

    if not profile then
        return false
    end

    if product.Grants then
        if product.Grants.UltimateCharges then
            profile.UltimateCharges += product.Grants.UltimateCharges
        end

        if product.Grants.KnowledgeTokens then
            profile.KnowledgeTokens += product.Grants.KnowledgeTokens
        end

        if product.Grants.SupportPoints then
            profile.SupportPoints += product.Grants.SupportPoints
        end
    end

    applyPlayerAttributes(player)
    saveProfile(player)
    sendShopState(player, string.format("%s granted.", product.DisplayName))
    sendFeedback(player, string.format("Purchase complete: %s", product.DisplayName), "success")

    return true
end

local function grantKnowledgeTokens(player: Player, amount: number, reason: string)
    local profile = playerProfiles[player]

    if not profile or amount <= 0 then
        return
    end

    profile.KnowledgeTokens += amount
    applyPlayerAttributes(player)
    saveProfile(player)
    sendShopState(player, string.format("%s: +%d %s", reason, amount, ShopCatalog.CurrencyName or "Knowledge Tokens"))
end

local function promptPass(player: Player, key: string)
    local item = gamePassByKey[key]

    if not item then
        sendFeedback(player, "That pass is not configured.", "warning")
        return
    end

    if item.ProductId <= 0 then
        sendFeedback(player, string.format("Create the %s pass in Creator Hub and paste the ProductId first.", item.DisplayName), "warning")
        return
    end

    MarketplaceService:PromptGamePassPurchase(player, item.ProductId)
end

local function promptProduct(player: Player, key: string)
    local item = developerProductByKey[key]

    if not item then
        sendFeedback(player, "That product is not configured.", "warning")
        return
    end

    if item.ProductId <= 0 then
        sendFeedback(player, string.format("Create the %s developer product in Creator Hub and paste the ProductId first.", item.DisplayName), "warning")
        return
    end

    MarketplaceService:PromptProductPurchase(player, item.ProductId)
end

local function tryEquipSkin(player: Player, skinId: string)
    local profile = playerProfiles[player]
    local ownedPasses = playerPassOwnership[player] or {}

    if not profile then
        return
    end

    local ownedSkins = getOwnedSkins(ownedPasses)

    if not ownedSkins[skinId] then
        sendFeedback(player, "You do not own that skin yet.", "warning")
        return
    end

    profile.EquippedSkin = skinId
    applyPlayerAttributes(player)
    saveProfile(player)
    BattleLoadout.ApplyCurrentSkin(player)
    sendShopState(player, string.format("Equipped %s.", ShopCatalog.SkinDefinitions[skinId].DisplayName))
    sendFeedback(player, string.format("Equipped %s.", ShopCatalog.SkinDefinitions[skinId].DisplayName), "success")
end

local function useUltimateCharge(player: Player)
    local profile = playerProfiles[player]

    if not profile then
        return
    end

    if player:GetAttribute("InBattle") ~= true then
        sendFeedback(player, "Ultimates can only be used during a battle round.", "warning")
        return
    end

    if profile.UltimateCharges <= 0 then
        sendFeedback(player, "No ultimate charges left. Buy more in the shop.", "warning")
        return
    end

    local now = os.clock()
    local lastUse = ultimateCooldowns[player]

    if lastUse and now - lastUse < 18 then
        sendFeedback(player, "Your ultimate is recharging.", "warning")
        return
    end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local currentScenarioId = player:GetAttribute("CurrentScenarioId")
    local currentBattleTeam = player:GetAttribute("CurrentBattleTeam")

    if not character or not root or not root:IsA("BasePart") or typeof(currentScenarioId) ~= "string" or typeof(currentBattleTeam) ~= "string" then
        sendFeedback(player, "Your ultimate could not be activated right now.", "warning")
        return
    end

    profile.UltimateCharges -= 1
    ultimateCooldowns[player] = now
    applyPlayerAttributes(player)
    saveProfile(player)

    local pulse = Instance.new("Part")
    pulse.Name = "UltimatePulse"
    pulse.Shape = Enum.PartType.Ball
    pulse.Material = Enum.Material.Neon
    pulse.Color = Color3.fromRGB(230, 199, 121)
    pulse.Transparency = 0.35
    pulse.Anchored = true
    pulse.CanCollide = false
    pulse.CanTouch = false
    pulse.CanQuery = false
    pulse.Size = Vector3.new(2, 2, 2)
    pulse.CFrame = CFrame.new(root.Position)
    pulse.Parent = Workspace

    local tween = TweenService:Create(
        pulse,
        TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Size = Vector3.new(44, 44, 44),
            Transparency = 1,
        }
    )
    tween:Play()
    Debris:AddItem(pulse, 0.6)

    for _, descendant in ipairs(Workspace:GetDescendants()) do
        if descendant:IsA("Humanoid") and descendant.Health > 0 then
            local targetModel = descendant.Parent

            if targetModel and targetModel:IsA("Model") and targetModel ~= character then
                local targetScenarioId = targetModel:GetAttribute("ScenarioId")
                local targetTeamId = targetModel:GetAttribute("BattleTeam")
                local targetRoot = targetModel:FindFirstChild("HumanoidRootPart")

                if targetScenarioId == currentScenarioId and targetTeamId ~= currentBattleTeam and targetRoot and targetRoot:IsA("BasePart") then
                    local offset = targetRoot.Position - root.Position
                    local distance = offset.Magnitude

                    if distance <= 22 then
                        descendant:TakeDamage(30)

                        if distance > 0.1 then
                            targetRoot.AssemblyLinearVelocity += offset.Unit * 52
                        end
                    end
                end
            end
        end
    end

    sendShopState(player, "Ultimate activated.")
    sendFeedback(player, "Ultimate activated.", "success")
end

requestShopState.OnServerEvent:Connect(function(player: Player)
    if not playerProfiles[player] then
        loadProfile(player)
        return
    end

    sendShopState(player)
end)

promptGamePassPurchase.OnServerEvent:Connect(function(player: Player, key: string)
    if typeof(key) == "string" then
        promptPass(player, key)
    end
end)

promptDeveloperProductPurchase.OnServerEvent:Connect(function(player: Player, key: string)
    if typeof(key) == "string" then
        promptProduct(player, key)
    end
end)

equipSkin.OnServerEvent:Connect(function(player: Player, skinId: string)
    if typeof(skinId) == "string" then
        tryEquipSkin(player, skinId)
    end
end)

useUltimate.OnServerEvent:Connect(function(player: Player)
    useUltimateCharge(player)
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
    if not wasPurchased then
        return
    end

    local item = gamePassByProductId[gamePassId]

    if not item then
        return
    end

    refreshPassOwnership(player)
    sendShopState(player, string.format("Unlocked %s.", item.DisplayName))
    sendFeedback(player, string.format("Unlocked %s.", item.DisplayName), "success")
end)

MarketplaceService.ProcessReceipt = function(receiptInfo)
    local item = developerProductByProductId[receiptInfo.ProductId]

    if not item then
        warn(string.format("[ShopService] No receipt handler for product id %s", tostring(receiptInfo.ProductId)))
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)

    if not player then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local receiptKey = string.format("receipt_%s", tostring(receiptInfo.PurchaseId))
    local alreadyProcessed = false

    local success, errorMessage = pcall(function()
        receiptStore:UpdateAsync(receiptKey, function(existing)
            if existing then
                alreadyProcessed = true
                return existing
            end

            return {
                ProductId = receiptInfo.ProductId,
                PlayerId = receiptInfo.PlayerId,
                ProcessedAt = os.time(),
            }
        end)
    end)

    if not success then
        warn(string.format("[ShopService] Failed to lock receipt %s: %s", tostring(receiptInfo.PurchaseId), tostring(errorMessage)))
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    if alreadyProcessed then
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end

    local granted = grantDeveloperProduct(player, item)

    if granted then
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end

    return Enum.ProductPurchaseDecision.NotProcessedYet
end

if grantCurrency and grantCurrency:IsA("BindableEvent") then
    grantCurrency.Event:Connect(function(player: Player, amount: number, reason: string?)
        grantKnowledgeTokens(player, amount, reason or "Reward")
    end)
end

Players.PlayerAdded:Connect(function(player)
    loadProfile(player)
end)

Players.PlayerRemoving:Connect(function(player)
    saveProfile(player)
    playerProfiles[player] = nil
    playerPassOwnership[player] = nil
    ultimateCooldowns[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        loadProfile(player)
    end)
end
