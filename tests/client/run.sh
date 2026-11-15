#!/usr/bin/env bash
# Client smoke test: builds the server (every server script) in the simulation engine, joins
# one simulated player as the local player, runs every LocalScript in StarterPlayerScripts
# against it, then presses every button the HUDs create and feeds the HUDs real server
# messages. It fails if a client script errors while loading or while handling a press or a
# message. It does not check layout or looks; that still needs Studio.
# Usage: tests/client/run.sh [path-to-luau-binary]
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
luau="${1:-${LUAU:-luau}}"
bundle="${CLIENT_BUNDLE:-$(mktemp -d)/client.luau}"

register() {
    local file="$1" path="$2"
    echo "registerModule(\"$path\", function(script)"
    sed -E 's/^export type /type /' "$file"
    echo "end)"
}

{
    cat "$root/tests/hub/mock.luau"
    cat "$root/tests/sim/engine.luau"
    cat "$root/tests/client/engine_ext.luau"

    for file in "$root"/src/ReplicatedStorage/Shared/*/*.lua "$root"/src/ServerScriptService/Modules/*.lua; do
        rel="${file#"$root"/src/}"
        register "$file" "${rel%.lua}"
    done

    for file in "$root"/src/StarterPlayer/StarterPlayerScripts/*.lua; do
        case "$file" in *.client.lua) continue ;; esac
        rel="${file#"$root"/src/}"
        register "$file" "${rel%.lua}"
    done

    echo 'serverFailures = {}'
    for file in "$root"/src/ServerScriptService/*.server.lua; do
        name="$(basename "$file" .server.lua)"
        echo "do local ok, err = pcall(sim.runScript, \"$name\", function()"
        echo "local script = scriptAt(\"ServerScriptService/$name\")"
        sed -E 's/^export type /type /' "$file"
        echo "end) if not ok then table.insert(serverFailures, \"$name: \" .. tostring(err)) end end"
    done

    cat "$root/tests/client/client.luau"

    for file in "$root"/src/StarterPlayer/StarterPlayerScripts/*.client.lua; do
        name="$(basename "$file" .client.lua)"
        echo "runClient(\"$name\", function()"
        echo "local script = scriptAt(\"StarterPlayer/StarterPlayerScripts/$name\")"
        sed -E 's/^export type /type /' "$file"
        echo "end)"
    done

    cat "$root/tests/client/checks.luau"
} > "$bundle"

"$luau" "$bundle"
