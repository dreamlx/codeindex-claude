#!/bin/sh
# SessionStart hook: verify the `codeindex` CLI is on PATH.
# Claude Code plugin spec has no declarative `requires` field for external
# binaries, so we self-check at session start and print a clear install hint.

if command -v codeindex >/dev/null 2>&1; then
    exit 0
fi

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

# Exit 0 — don't block the session, just warn.
exit 0
