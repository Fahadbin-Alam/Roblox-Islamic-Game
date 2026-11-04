#!/usr/bin/env bash
# Type-checks every script against the Roblox API with luau-lsp and fails on the error
# classes that crash at runtime: syntax errors, unknown globals (usually a local used before
# it is declared), and requires that do not resolve. The remaining strict-mode type warnings
# are reported but not fatal yet.
# Usage: tests/analyze.sh <luau-lsp> <rojo> <globalTypes.d.luau>
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
lsp="${1:?luau-lsp path}"
rojo="${2:?rojo path}"
defs="${3:?Roblox type definitions path}"
work="$(mktemp -d)"

cd "$root"
"$rojo" sourcemap default.project.json -o "$work/sourcemap.json"
"$lsp" analyze --definitions="$defs" --sourcemap="$work/sourcemap.json" src > "$work/report.txt" 2>&1 || true

fatal="$(grep -E "SyntaxError|Unknown global|Unknown require|UnknownRequire" "$work/report.txt" || true)"
total="$(grep -cE "TypeError|SyntaxError" "$work/report.txt" || true)"

echo "luau-lsp reported $total type diagnostics."

if [ -n "$fatal" ]; then
    echo "Runtime-breaking problems:"
    echo "$fatal"
    exit 1
fi

echo "No syntax errors, unknown globals, or broken requires."
