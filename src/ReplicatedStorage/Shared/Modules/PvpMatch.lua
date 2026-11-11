--!strict

-- Pure state machine for the Training Grounds PvP arena (free-for-all sparring, 2-8 players).
-- The Roblox service applies real damage through the battle tools and reports knockouts and
-- timeouts here; this module decides rounds, match winners, and rematches. It is unit tested
-- with two and more players.

local PvpMatch = {}

export type Config = {
    MinPlayers: number,
    MaxPlayers: number,
    RoundsToWin: number,
    RoundSeconds: number,
}

export type Match = {
    Config: Config,
    Players: { number },
    Alive: { [number]: boolean },
    Wins: { [number]: number },
    Knockouts: { [number]: number },
    Phase: string, -- "Waiting", "Round", "Intermission", "Over"
    Round: number,
    RoundWinner: number?,
    MatchWinner: number?,
    Rematch: { [number]: boolean },
}

PvpMatch.DefaultConfig = table.freeze({
    MinPlayers = 2,
    MaxPlayers = 8,
    RoundsToWin = 3,
    RoundSeconds = 90,
})

function PvpMatch.New(config: Config?): Match
    return {
        Config = config or PvpMatch.DefaultConfig,
        Players = {},
        Alive = {},
        Wins = {},
        Knockouts = {},
        Phase = "Waiting",
        Round = 0,
        RoundWinner = nil,
        MatchWinner = nil,
        Rematch = {},
    }
end

function PvpMatch.Has(match: Match, id: number): boolean
    return table.find(match.Players, id) ~= nil
end

-- Players can only join between rounds, so nobody drops into a fight halfway.
function PvpMatch.AddPlayer(match: Match, id: number): boolean
    if PvpMatch.Has(match, id) or #match.Players >= match.Config.MaxPlayers or match.Phase == "Round" then
        return false
    end

    table.insert(match.Players, id)
    match.Wins[id] = match.Wins[id] or 0
    match.Knockouts[id] = match.Knockouts[id] or 0

    return true
end

local function aliveList(match: Match): { number }
    local list = {}

    for _, id in ipairs(match.Players) do
        if match.Alive[id] then
            table.insert(list, id)
        end
    end

    return list
end

local function finishRound(match: Match, winner: number?)
    match.RoundWinner = winner
    match.Alive = {}

    if winner then
        match.Wins[winner] = (match.Wins[winner] or 0) + 1

        if match.Wins[winner] >= match.Config.RoundsToWin then
            match.Phase = "Over"
            match.MatchWinner = winner
            return
        end
    end

    match.Phase = if #match.Players >= match.Config.MinPlayers then "Intermission" else "Waiting"
end

-- After a removal mid-round, the last player standing wins it.
local function checkRoundEnd(match: Match)
    if match.Phase ~= "Round" then
        return
    end

    local alive = aliveList(match)

    if #alive <= 1 then
        finishRound(match, alive[1])
    end
end

function PvpMatch.RemovePlayer(match: Match, id: number)
    local index = table.find(match.Players, id)

    if not index then
        return
    end

    table.remove(match.Players, index)
    match.Alive[id] = nil
    match.Rematch[id] = nil
    checkRoundEnd(match)

    if match.Phase ~= "Round" and match.Phase ~= "Over" and #match.Players < match.Config.MinPlayers then
        match.Phase = "Waiting"
    end
end

function PvpMatch.CanStartRound(match: Match): boolean
    return (match.Phase == "Waiting" or match.Phase == "Intermission") and #match.Players >= match.Config.MinPlayers
end

function PvpMatch.StartRound(match: Match): boolean
    if not PvpMatch.CanStartRound(match) then
        return false
    end

    match.Phase = "Round"
    match.Round += 1
    match.RoundWinner = nil
    match.Alive = {}

    for _, id in ipairs(match.Players) do
        match.Alive[id] = true
    end

    return true
end

-- A player was knocked out. `attacker` gets the knockout if they are another living fighter.
function PvpMatch.Knockout(match: Match, target: number, attacker: number?): boolean
    if match.Phase ~= "Round" or not match.Alive[target] then
        return false
    end

    match.Alive[target] = nil

    if attacker and attacker ~= target and PvpMatch.Has(match, attacker) then
        match.Knockouts[attacker] = (match.Knockouts[attacker] or 0) + 1
    end

    checkRoundEnd(match)

    return true
end

-- Time ran out: the living player with the most health wins the round; a tie is a draw.
function PvpMatch.Timeout(match: Match, healthById: { [number]: number })
    if match.Phase ~= "Round" then
        return
    end

    local best, bestHealth, tie = nil, -1, false

    for _, id in ipairs(aliveList(match)) do
        local health = healthById[id] or 0

        if health > bestHealth then
            best, bestHealth, tie = id, health, false
        elseif health == bestHealth then
            tie = true
        end
    end

    finishRound(match, if tie then nil else best)
end

-- Once the match is over, every remaining player must vote to play again (at least the
-- minimum). Returns true when the rematch begins: scores reset and the next round can start.
function PvpMatch.VoteRematch(match: Match, id: number): boolean
    if match.Phase ~= "Over" or not PvpMatch.Has(match, id) then
        return false
    end

    match.Rematch[id] = true

    for _, playerId in ipairs(match.Players) do
        if not match.Rematch[playerId] then
            return false
        end
    end

    if #match.Players < match.Config.MinPlayers then
        return false
    end

    for _, playerId in ipairs(match.Players) do
        match.Wins[playerId] = 0
        match.Knockouts[playerId] = 0
    end

    match.Rematch = {}
    match.Round = 0
    match.MatchWinner = nil
    match.RoundWinner = nil
    match.Phase = "Intermission"

    return true
end

function PvpMatch.Snapshot(match: Match)
    local rows = {}

    for _, id in ipairs(match.Players) do
        table.insert(rows, {
            UserId = id,
            Wins = match.Wins[id] or 0,
            Knockouts = match.Knockouts[id] or 0,
            Alive = match.Alive[id] == true,
            Rematch = match.Rematch[id] == true,
        })
    end

    return {
        Phase = match.Phase,
        Round = match.Round,
        RoundsToWin = match.Config.RoundsToWin,
        RoundWinner = match.RoundWinner,
        MatchWinner = match.MatchWinner,
        Players = rows,
    }
end

return PvpMatch
