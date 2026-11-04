#!/usr/bin/env bash
# Runs the pure-Luau unit tests (shared data and progression rules) outside Roblox Studio.
# Usage: tests/luau/run.sh [path-to-luau-binary]
# Each ModuleScript under src/ReplicatedStorage/Shared is bundled into one file with a small
# mock of `script`, `require`, and the few Roblox datatypes the data files construct.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
luau="${1:-${LUAU:-luau}}"
shared="$root/src/ReplicatedStorage/Shared"
bundle="$(mktemp -d)/bundle.luau"

{
    cat "$root/tests/luau/prelude.luau"

    for file in "$shared"/*/*.lua; do
        rel="${file#"$shared"/}"
        name="${rel%.lua}"
        echo "loaders[\"$name\"] = function(script)"
        # `export type` is only legal at the top level, so drop the keyword inside the wrapper.
        sed -E 's/^export type /type /' "$file"
        echo "end"
    done

    for test in "$root"/tests/luau/*.spec.luau; do
        echo "do"
        echo "currentSpec = \"$(basename "$test")\""
        cat "$test"
        echo "end"
    done

    echo "finish()"
} > "$bundle"

"$luau" "$bundle"
