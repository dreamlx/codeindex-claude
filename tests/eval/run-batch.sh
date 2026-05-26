#!/bin/sh
# Batch runner: each prompt in prompts.tsv runs twice — without plugin (A)
# and with plugin (B) — both in headless mode with stream-json capture.
# Output: runs/<id>-A.jsonl and runs/<id>-B.jsonl (gitignored).

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUN_DIR="$SCRIPT_DIR/runs"
mkdir -p "$RUN_DIR"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/plugins/codeindex"

# Run from a throwaway tmp dir so local-scope plugins don't auto-load.
# Without this, cwd inside the plugin's project-path causes the user-installed
# codeindex plugin to load even when we're trying to test "condition A = no plugin".
WORK_TMP="$(mktemp -d)"
cd "$WORK_TMP"

echo "Plugin: $PLUGIN_DIR"
echo "Repo (via --add-dir): $REPO_ROOT"
echo "Cwd (neutral): $WORK_TMP"
echo "Output: $RUN_DIR"
echo "---"

while IFS="$(printf '\t')" read -r id prompt expected; do
    case "$id" in
        ''|\#*) continue ;;
    esac

    echo ">> $id  (expected: $expected)"

    echo "   A: no plugin"
    claude -p "$prompt" \
        --add-dir "$REPO_ROOT" \
        --output-format stream-json --verbose \
        --no-session-persistence --max-budget-usd 0.50 \
        > "$RUN_DIR/${id}-A.jsonl" 2>&1 || echo "   (A errored, jsonl saved)"

    echo "   B: with plugin"
    claude -p "$prompt" \
        --plugin-dir "$PLUGIN_DIR" \
        --add-dir "$REPO_ROOT" \
        --output-format stream-json --verbose \
        --no-session-persistence --max-budget-usd 0.50 \
        > "$RUN_DIR/${id}-B.jsonl" 2>&1 || echo "   (B errored, jsonl saved)"
done < "$SCRIPT_DIR/prompts.tsv"

echo "---"
echo "Done. Run: python3 $SCRIPT_DIR/eval.py"
