--!strict

local BattleAnimationLibrary = {
    Sword = {
        Idle = {
            AnimationId = "",
            Priority = Enum.AnimationPriority.Idle,
            FadeTime = 0.18,
            Speed = 1,
            Looped = true,
        },
        Equip = {
            AnimationId = "",
            Priority = Enum.AnimationPriority.Action,
            FadeTime = 0.08,
            Speed = 1,
            Looped = false,
        },
        Slash = {
            AnimationId = "",
            Priority = Enum.AnimationPriority.Action,
            FadeTime = 0.06,
            Speed = 1.08,
            Looped = false,
        },
    },
    Bow = {
        Idle = {
            AnimationId = "",
            Priority = Enum.AnimationPriority.Idle,
            FadeTime = 0.18,
            Speed = 1,
            Looped = true,
        },
        Equip = {
            AnimationId = "",
            Priority = Enum.AnimationPriority.Action,
            FadeTime = 0.08,
            Speed = 1,
            Looped = false,
        },
        DrawLoop = {
            AnimationId = "",
            Priority = Enum.AnimationPriority.Action,
            FadeTime = 0.08,
            Speed = 1,
            Looped = true,
        },
        Release = {
            AnimationId = "",
            Priority = Enum.AnimationPriority.Action,
            FadeTime = 0.06,
            Speed = 1.04,
            Looped = false,
        },
    },
}

function BattleAnimationLibrary.HasAnimation(entry): boolean
    if typeof(entry) ~= "table" then
        return false
    end

    local animationId = entry.AnimationId

    return typeof(animationId) == "string" and animationId ~= "" and animationId ~= "rbxassetid://0"
end

return table.freeze(BattleAnimationLibrary)
