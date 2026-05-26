#!/bin/sh
# SessionStart hook: verify the `codeindex` CLI is on PATH and recent enough.
# Claude Code plugin spec has no declarative `requires` field for external
# binaries, so we self-check at session start and print actionable hints.

MIN_CLI_VERSION="0.25.0"

if ! command -v codeindex >/dev/null 2>&1; then
    cat <<'EOF' >&2

⚠  codeindex plugin loaded but the `codeindex` CLI is not on PATH.

   The plugin's skills (codeindex:arch / :index / :hooks / :update-guide)
   shell out to `codeindex`. Without the CLI installed they will fail.

   Install (recommended):
       pipx install ai-codeindex

   Or, if you don't have pipx:
       pip install --user ai-codeindex

   See https://github.com/dreamlx/codeindex for full setup.

EOF
    exit 0
fi

INSTALLED=$(codeindex --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)

if [ -n "$INSTALLED" ] && \
   [ "$(printf '%s\n%s\n' "$MIN_CLI_VERSION" "$INSTALLED" | sort -V | head -1)" != "$MIN_CLI_VERSION" ]; then
    cat <<EOF >&2

⚠  codeindex $INSTALLED detected, but this plugin needs >= $MIN_CLI_VERSION.

   Several skill commands (codeindex claude-md, affected, etc.) rely on
   the newer CLI. Upgrade:

       pipx upgrade ai-codeindex

EOF
fi

exit 0
