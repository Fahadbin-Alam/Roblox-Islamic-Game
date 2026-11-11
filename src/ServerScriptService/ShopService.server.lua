--!strict

-- Shop, battle skins, ultimate charges and Robux purchases. The monetization profile
-- (equipped skin, ultimate charges, tokens, support points) is saved through SessionStore,
-- and a developer product is only reported to Roblox as granted after the grant is saved.

local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ShopCatalog = require(Shared.Data.ShopCatalog)
local BattleLoadout = require(script.Parent.Modules.BattleLoadout)
local PlayerProgress = require(script.Parent.Modules.PlayerProgress)
local SessionStore = require(script.Parent.Modules.SessionStore)

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
local sessionStore = SessionStore.new(profileStore :: any, {
    JobId = game.JobId,
    Now = os.time,
    Wait = function(seconds: number)
        task.wait(seconds)
    end,
    NewId = function()
        return HttpService:GenerateGUID(false)
    end,
    Log = function(message: string)
        warn("[ShopService] " .. message)
    end,
})

type ShopProfile = {
    EquippedSkin: string,
    UltimateCharges: number,
    KnowledgeTokens: number,
    SupportPoints: number,
    -- Recent developer-product PurchaseIds already granted, saved in the same record as the
    -- grant itself, so a receipt Roblox retries can never be granted twice or lost.
    PurchaseIds: { string },
}

local playerProfiles: { [Player]: ShopProfile } = {}
local playerPassOwnership: { [Player]: { [string]: boolean } } = {}
local ultimateCooldowns: { [Player]: number } = {}
-- Open DataStore sessions. A player without one (the load failed) keeps a working default
-- profile that is never saved, so an outage cannot wipe their real data.
local sessions: { [Player]: any } = {}
local loading: { [Player]: boolean } = {}
local closingCount = 0
local COMBATANT_TAG = "BattleCombatant"
local MAX_REMEMBERED_PURCHASES = 100
local LOCK_REFRESH_SECONDS = 10 * 60

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

local function buildDefaultProfile(): ShopProfile
    return {
        EquippedSkin = "default",
        UltimateCharges = 0,
        KnowledgeTokens = 0,
        SupportPoints = 0,
        PurchaseIds = {},
    }
end

local function cloneProfile(source: ShopProfile)
    return {
        EquippedSkin = source.EquippedSkin,
        UltimateCharges = source.UltimateCharges,
        KnowledgeTokens = source.KnowledgeTokens,
        SupportPoints = source.SupportPoints,
        PurchaseIds = table.clone(source.PurchaseIds),
    }
end

local function sendFeedback(player: Player, text: string, tone: string?)
    purchaseFeedback:FireClient(player, {
        Text = text,
        Tone = tone or "info",
    })
end

local function playerLevel(player: Player): number
    local level = player:GetAttribute("Level")

    return if type(level) == "number" then level else 0
end

local function getOwnedSkins(player: Player, ownedPasses: { [string]: boolean }): { [string]: boolean }
    local ownedSkins = {
        default = true,
    }

    for skinId, skinDefinition in pairs(ShopCatalog.SkinDefinitions) do
        if skinDefinition.UnlockType == "GamePass" and ownedPasses[skinDefinition.UnlockKey] then
            ownedSkins[skinId] = true
        elseif skinDefinition.UnlockType == "Level" and playerLevel(player) >= (skinDefinition.UnlockLevel or math.huge) then
            ownedSkins[skinId] = true
        end
    end

    return ownedSkins
end

local function sanitizeEquippedSkin(player: Player, profile, ownedPasses: { [string]: boolean })
    local ownedSkins = getOwnedSkins(player, ownedPasses)

    if ownedSkins[profile.EquippedSkin] then
        return
    end

    -- Level skins are only taken off once the player's real level is known, so a slow or
    -- failed progress load never strips a skin they earned.
    local definition = ShopCatalog.SkinDefinitions[profile.EquippedSkin]

    if definition and definition.UnlockType == "Level" and not PlayerProgress.IsSaveable(player) then
        return
    end

    profile.EquippedSkin = "default"
end

local function applyPlayerAttributes(player: Player)
    local profile = playerProfiles[player]

    -- Not loaded yet: loadProfile applies the attributes when it finishes. Creating a blank
    -- profile here would make the shop look loaded before it is.
    if not profile then
        return
    end

    local ownedPasses = playerPassOwnership[player] or {}

    sanitizeEquippedSkin(player, profile, ownedPasses)

    player:SetAttribute("EquippedBattleSkin", profile.EquippedSkin)
    player:SetAttribute("UltimateCharges", profile.UltimateCharges)
    player:SetAttribute("KnowledgeTokens", profile.KnowledgeTokens)
    player:SetAttribute("SupportPoints", profile.SupportPoints)
    player:SetAttribute("HasFounderSupport", ownedPasses.founder_support == true)
end

-- Saves now and yields until the DataStore answers. Returns true when the data is stored.
local function saveProfileNow(player: Player): boolean
    local profile = playerProfiles[player]
    local session = sessions[player]

    -- A profile that failed to load is a blank default; saving it would wipe the player's real data.
    if not profile or not session then
        return false
    end

    local saved = session:Save(cloneProfile(profile))

    if not saved then
        warn(string.format("[ShopService] Failed to save profile for %s%s", player.Name, if session.Lost then " (open in another server)" else ""))
    end

    return saved
end

-- Saves in the background. SessionStore queues saves per player, so they land in order.
local function saveProfile(player: Player)
    task.spawn(saveProfileNow, player)
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
    local ownedSkins = getOwnedSkins(player, ownedPasses)

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

local function closeSession(player: Player, session: any, data: ShopProfile)
    closingCount += 1
    local saved = session:Close(cloneProfile(data))
    closingCount -= 1

    if not saved and not session.Lost then
        warn(string.format("[ShopService] Final save failed for %s", player.Name))
    end
end

local function loadProfile(player: Player)
    -- PlayerAdded and the client's first RequestShopState both arrive while the load is
    -- still waiting on the DataStore; only one load may run, or the second would replace a
    -- profile that may already hold a new purchase.
    if loading[player] or playerProfiles[player] then
        return
    end

    loading[player] = true
    local profile = buildDefaultProfile()
    local session, storedProfile = sessionStore:Open(string.format("player_%d", player.UserId), { player.UserId })
    loading[player] = nil

    if session and type(storedProfile) == "table" then
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

        if type(storedProfile.PurchaseIds) == "table" then
            for _, purchaseId in ipairs(storedProfile.PurchaseIds) do
                if type(purchaseId) == "string" then
                    table.insert(profile.PurchaseIds, purchaseId)
                end
            end
        end
    elseif not session then
        warn(string.format("[ShopService] Failed to load profile for %s; purchases are paused for this visit", player.Name))
    end

    if not player.Parent then
        -- Left while loading: write back what was loaded and release the lock.
        if session then
            closeSession(player, session, profile)
        end

        return
    end

    sessions[player] = session
    playerProfiles[player] = profile
    refreshPassOwnership(player)
    sendShopState(player, "Shop ready.")
end

local function applyGrants(profile: ShopProfile, product, sign: number)
    local grants = product.Grants

    if not grants then
        return
    end

    profile.UltimateCharges += sign * (grants.UltimateCharges or 0)
    profile.KnowledgeTokens += sign * (grants.KnowledgeTokens or 0)
    profile.SupportPoints += sign * (grants.SupportPoints or 0)
end

-- Grants a developer product and returns true only once the grant (and its PurchaseId) is
-- saved. On a failed save the grant is undone, so Roblox's retry of the receipt grants it
-- for real instead of the player losing it when they leave.
local function grantDeveloperProduct(player: Player, product, purchaseId: string): boolean
    local profile = playerProfiles[player]
    local session = sessions[player]

    if not profile or not session or session.Lost then
        return false
    end

    if table.find(profile.PurchaseIds, purchaseId) then
        return true
    end

    applyGrants(profile, product, 1)
    table.insert(profile.PurchaseIds, purchaseId)

    while #profile.PurchaseIds > MAX_REMEMBERED_PURCHASES do
        table.remove(profile.PurchaseIds, 1)
    end

    if not saveProfileNow(player) then
        applyGrants(profile, product, -1)
        local index = table.find(profile.PurchaseIds, purchaseId)

        if index then
            table.remove(profile.PurchaseIds, index)
        end

        return false
    end

    applyPlayerAttributes(player)
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

    local ownedSkins = getOwnedSkins(player, ownedPasses)

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

    for _, targetModel in ipairs(CollectionService:GetTagged(COMBATANT_TAG)) do
        if targetModel:IsA("Model") and targetModel ~= character then
            local targetHumanoid = targetModel:FindFirstChildOfClass("Humanoid")
            local targetScenarioId = targetModel:GetAttribute("ScenarioId")
            local targetTeamId = targetModel:GetAttribute("BattleTeam")
            local targetRoot = targetModel:FindFirstChild("HumanoidRootPart")

            if targetHumanoid and targetHumanoid.Health > 0 and targetScenarioId == currentScenarioId and targetTeamId ~= currentBattleTeam and targetRoot and targetRoot:IsA("BasePart") then
                local offset = targetRoot.Position - root.Position
                local distance = offset.Magnitude

                if distance <= 22 then
                    targetHumanoid:TakeDamage(30)

                    if distance > 0.1 then
                        targetRoot.AssemblyLinearVelocity += offset.Unit * 52
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
        -- Still loading (the state is sent when it finishes) or the first load never ran.
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

    -- Not in this server, or their data is not loaded and saveable: Roblox retries the
    -- receipt later (including when they next join), so nothing is lost by waiting.
    if not player or not playerProfiles[player] or not sessions[player] then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    if grantDeveloperProduct(player, item, tostring(receiptInfo.PurchaseId)) then
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

local function releasePlayer(player: Player)
    local profile = playerProfiles[player]
    local session = sessions[player]

    playerProfiles[player] = nil
    sessions[player] = nil
    playerPassOwnership[player] = nil
    ultimateCooldowns[player] = nil

    if profile and session and not session.Lost then
        closeSession(player, session, profile)
    end
end

Players.PlayerRemoving:Connect(releasePlayer)

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        loadProfile(player)
    end)
end

game:BindToClose(function()
    for player in pairs(playerProfiles) do
        task.spawn(releasePlayer, player)
    end

    -- Wait for every final save in flight, including those PlayerRemoving started.
    local deadline = os.clock() + 25

    while closingCount > 0 and os.clock() < deadline do
        task.wait(0.1)
    end
end)

-- Shop data only saves when it changes, so refresh the session lock now and then; a lock
-- that is never refreshed would look like a crashed server to the player's next server.
task.spawn(function()
    while true do
        task.wait(60)

        for player, session in pairs(sessions) do
            if not session.Lost and os.time() - session.LastSavedAt >= LOCK_REFRESH_SECONDS then
                saveProfile(player)
            end
        end
    end
end)
