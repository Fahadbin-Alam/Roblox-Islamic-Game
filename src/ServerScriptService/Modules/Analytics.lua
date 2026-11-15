--!strict

-- Thin, crash-proof wrapper over Roblox AnalyticsService. Events appear in Creator Hub under
-- Analytics (Funnels, Custom events, Economy) once the experience is published. In Studio and
-- in tests the calls are skipped quietly if the service refuses them.
--
-- What is tracked, and how it maps to the business goals, is described in
-- docs/monetization-setup.md ("Measuring revenue, retention, and costs").

local AnalyticsService = game:GetService("AnalyticsService")

local Analytics = {}

local function safe(fn: () -> ())
    local ok, err = pcall(fn)

    if not ok then
        -- Analytics must never break gameplay. Warn once per kind of failure.
        local key = tostring(err):sub(1, 60)

        if not (Analytics :: any)._warned then
            (Analytics :: any)._warned = {}
        end

        if not (Analytics :: any)._warned[key] then
            (Analytics :: any)._warned[key] = true
            warn("[Analytics] " .. tostring(err))
        end
    end
end

-- Onboarding funnel: 1 joined, 2 first lesson or chapter, 3 first completion, 4 level 3.
function Analytics.Onboarding(player: Player, step: number, stepName: string)
    safe(function()
        AnalyticsService:LogOnboardingFunnelStepEvent(player, step, stepName)
    end)
end

function Analytics.Funnel(player: Player, funnelName: string, step: number, stepName: string)
    safe(function()
        AnalyticsService:LogFunnelStepEvent(player, funnelName, nil, step, stepName)
    end)
end

function Analytics.Custom(player: Player, eventName: string, value: number?)
    safe(function()
        AnalyticsService:LogCustomEvent(player, eventName, value or 1)
    end)
end

-- Knowledge Tokens earned (Source) or spent (Sink), so the in-game economy shows in Creator Hub.
function Analytics.Economy(player: Player, earned: boolean, amount: number, endingBalance: number, transactionType: string, sku: string?)
    safe(function()
        AnalyticsService:LogEconomyEvent(
            player,
            if earned then Enum.AnalyticsEconomyFlowType.Source else Enum.AnalyticsEconomyFlowType.Sink,
            "KnowledgeTokens",
            amount,
            endingBalance,
            transactionType,
            sku
        )
    end)
end

return Analytics
