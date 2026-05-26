#!/bin/sh
# Contract test: verify every CLI subcommand the plugin skills depend on
# actually exists in the installed `codeindex` CLI. Run by CI after
# `pipx install ai-codeindex` (or git+...@develop).
#
# Whitelist is `expected-commands.txt` — one subcommand per line.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WHITELIST="$SCRIPT_DIR/expected-commands.txt"

if ! command -v codeindex >/dev/null 2>&1; then
    echo "FAIL: codeindex CLI not on PATH" >&2
    exit 1
fi

echo "Installed CLI: $(codeindex --version)"
echo "Whitelist:     $WHITELIST"
echo "---"

fail_count=0
pass_count=0
while IFS= read -r raw; do
    # Strip trailing whitespace; skip blank lines and comments.
    cmd=$(printf '%s' "$raw" | sed 's/[[:space:]]*$//')
    case "$cmd" in
        ''|\#*) continue ;;
    esac

    # `codeindex <cmd> --help` — splitting $cmd on whitespace is intentional
    # so multi-word subcommands like `claude-md update` work.
    # shellcheck disable=SC2086
    if codeindex $cmd --help >/dev/null 2>&1; then
        printf '  \033[32m✓\033[0m codeindex %s\n' "$cmd"
        pass_count=$((pass_count + 1))
    else
        printf '  \033[31m✗\033[0m codeindex %s  (--help failed)\n' "$cmd" >&2
        fail_count=$((fail_count + 1))
    fi
done < "$WHITELIST"

echo "---"
if [ "$fail_count" -gt 0 ]; then
    echo "FAIL: $fail_count missing, $pass_count present" >&2
    exit 1
fi

echo "PASS: all $pass_count commands available"
