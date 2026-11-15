#!/usr/bin/env bash
# Writes a single Luau file that loads the mock engine, the shared modules, BuildUtils and
# the battle arena builder, followed by the given Luau files. Usage: bundle.sh out.luau files...
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
out="$1"
shift
shared="$root/src/ReplicatedStorage/Shared"
server="$root/src/ServerScriptService"

{
    cat "$root/tests/world/mock.luau"
    cat "$root/tests/world/geometry.luau"
    echo 'local __rs = game:GetService("ReplicatedStorage")'
    echo 'local __shared = Instance.new("Folder"); __shared.Name = "Shared"; __shared.Parent = __rs'
    echo 'local __sss = game:GetService("ServerScriptService")'
    echo 'local __serverModules = Instance.new("Folder"); __serverModules.Name = "Modules"; __serverModules.Parent = __sss'

    for dir in "$shared"/*/; do
        group="$(basename "$dir")"
        echo "local __g_$group = Instance.new(\"Folder\"); __g_$group.Name = \"$group\"; __g_$group.Parent = __shared"
        for file in "$dir"*.lua; do
            name="$(basename "$file" .lua)"
            echo "makeModule(__g_$group, \"$name\", function(script)"
            sed -E 's/^export type /type /' "$file"
            echo "end)"
        done
    done

    for file in "$server"/Modules/*.lua; do
        name="$(basename "$file" .lua)"
        case "$name" in
            BuildUtils|MissionLayout)
                echo "makeModule(__serverModules, \"$name\", function(script)"
                sed -E 's/^export type /type /' "$file"
                echo "end)"
                ;;
        esac
    done

    echo "do"
    echo "local script = { Parent = __sss, Name = \"BattleArenaBuilder\" }"
    cat "$server/BattleArenaBuilder.server.lua"
    echo "end"

    for extra in "$@"; do
        echo "do"
        cat "$extra"
        echo "end"
    done
} > "$out"
