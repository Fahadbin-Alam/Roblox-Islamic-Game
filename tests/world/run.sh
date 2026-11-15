#!/usr/bin/env bash
# Builds the battle arenas with a mock of the Roblox engine and checks the mission layouts:
# every point has ground and room to stand, every enemy lane and player route can be walked
# in straight lines, and team spawns are not inside rock.
# Usage: tests/world/run.sh [path-to-luau-binary]
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
luau="${1:-${LUAU:-luau}}"
bundle="$(mktemp -d)/world.luau"

"$root/tests/world/bundle.sh" "$bundle" "$root/tests/world/arenas.spec.luau"
"$luau" "$bundle"
