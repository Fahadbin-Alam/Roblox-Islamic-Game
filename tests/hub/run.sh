#!/usr/bin/env bash
# Runs the hub world builder (HubWorldBuilder and the Masjid al-Haram module) and the activity
# zone builders (historical towns, mystery wing, co-op trials, training grounds) inside a mock
# Roblox engine and checks the result: it builds without errors, stays inside a part budget,
# keeps the arrival spawn clear, and places the landmarks the learning trail talks about.
# Usage: tests/hub/run.sh [path-to-luau-binary] [--dump | --dump-all]
#   --dump prints every part as a PART| line instead (feed it to tests/hub/render.py).
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
luau="${1:-${LUAU:-luau}}"
mode="${2:-check}"
bundle="$(mktemp -d)/hub.luau"

register() {
    local file="$1" path="$2"
    echo "registerModule(\"$path\", function(script)"
    sed -E 's/^export type /type /' "$file"
    echo "end)"
}

{
    cat "$root/tests/hub/mock.luau"

    for file in "$root"/src/ReplicatedStorage/Shared/*/*.lua; do
        rel="${file#"$root"/src/}"
        register "$file" "${rel%.lua}"
    done

    for file in "$root"/src/ServerScriptService/Modules/*.lua; do
        rel="${file#"$root"/src/}"
        register "$file" "${rel%.lua}"
    done

    # Run the day/night service at 22:00 so the checks can see night mode.
    echo 'game:GetService("Lighting").ClockTime = 22'

    for name in GameBootstrap HubWorldBuilder HaramTimeService HistoricalWorldBuilder MysteryService CoopTrialsService PvpArenaService BattleArenaBuilder; do
        file="$root/src/ServerScriptService/$name.server.lua"
        [ -f "$file" ] || continue
        echo "do"
        echo "local script = scriptAt(\"ServerScriptService/$name\")"
        echo "local ok, err = pcall(function()"
        sed -E 's/^export type /type /' "$file"
        echo "end)"
        echo "if not ok then error(\"$name failed: \" .. tostring(err)) end"
        echo "end"
    done

    if [ "$mode" = "--dump" ] || [ "$mode" = "--dump-all" ]; then
        [ "$mode" = "--dump-all" ] && echo "DUMP_ALL = true"
        cat "$root/tests/hub/dump.luau"
    else
        cat "$root/tests/hub/checks.luau"
        cat "$root/tests/hub/zones.luau"
    fi
} > "$bundle"

"$luau" "$bundle"
