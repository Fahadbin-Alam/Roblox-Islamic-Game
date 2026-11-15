#!/usr/bin/env bash
# Runs real server scripts against simulated players in virtual time: two or more players join,
# fight, save, mute each other, and so on, through the same remotes the clients use.
# Built on the hub mock engine (tests/hub/mock.luau) plus tests/sim/engine.luau.
# Usage: tests/sim/run.sh [path-to-luau-binary]
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
luau="${1:-${LUAU:-luau}}"
bundle="$(mktemp -d)/sim.luau"

register() {
    local file="$1" path="$2"
    echo "registerModule(\"$path\", function(script)"
    sed -E 's/^export type /type /' "$file"
    echo "end)"
}

{
    cat "$root/tests/hub/mock.luau"
    cat "$root/tests/sim/engine.luau"

    for file in "$root"/src/ReplicatedStorage/Shared/*/*.lua "$root"/src/ServerScriptService/Modules/*.lua; do
        rel="${file#"$root"/src/}"
        register "$file" "${rel%.lua}"
    done

    for name in GameBootstrap ProgressionService PvpArenaService SocialService CoopTrialsService ParkourService HistoricalWorldBuilder SeerahCampaignService MysteryService; do
        echo "sim.runScript(\"$name\", function()"
        echo "local script = scriptAt(\"ServerScriptService/$name\")"
        sed -E 's/^export type /type /' "$root/src/ServerScriptService/$name.server.lua"
        echo "end)"
    done

    cat "$root/tests/sim/prelude.luau"

    for spec in "$root"/tests/sim/*.spec.luau; do
        echo "do"
        echo "currentSpec = \"$(basename "$spec")\""
        cat "$spec"
        echo "end"
    done

    echo "finish()"
} > "$bundle"

"$luau" "$bundle"
