---
name: update-guide
description: This skill should be used when the user asks to "refresh codeindex guide", "update CLAUDE.md codeindex section", "is my CLAUDE.md current", or upgrades the codeindex CLI and wants the project's CLAUDE.md guidance synced to the new version. Provides project-specific suggestions tailored to detected languages and config.
version: 0.1.3
---

# codeindex:update-guide — CLAUDE.md Refresh

Refresh the codeindex-managed section in `CLAUDE.md` (project or user-global) to match the installed codeindex CLI version, with project-specific suggestions.

> **Prereq**: `codeindex` CLI must be on PATH. The actual update is delegated to `codeindex claude-md update` — this skill is just a friendly walkthrough.

## Workflow

### Step 1: Detect Installed CLI Version

```bash
codeindex --version
```

Note the version for reporting.

### Step 2: Check Current CLAUDE.md State

```bash
codeindex claude-md status
```

This prints:
- Whether `CLAUDE.md` exists (project root vs `~/.claude/CLAUDE.md`)
- The codeindex-section version recorded inside
- Whether it's stale relative to the installed CLI

If everything is current, stop here and report "CLAUDE.md is up to date (v X.Y.Z)".

### Step 3: Analyze Project Profile

```bash
# Languages
codeindex list-dirs --languages 2>/dev/null

# Existing config
cat .codeindex.yaml 2>/dev/null

# Whether scan-all has been run
find . -name "README_AI.md" -type f | wc -l
```

Use this to tailor the suggestions in step 5.

### Step 4: Show What Will Change

```bash
codeindex claude-md update --dry-run
```

Display the diff to the user. **Do not apply without confirmation.**

### Step 5: Suggest Project-Specific Additions

Based on profile from step 3, suggest extras the user may want appended to CLAUDE.md, for example:

- If `tests/` has many subdirs and no README_AI.md → suggest adding "run `codeindex scan-all` to index tests"
- If `.codeindex.yaml` has `ai_command` configured → mention `scan-all --ai` and idempotent re-run pattern
- If post-commit hook is installed → suggest the "Documentation Auto-Updates" snippet from `codeindex:hooks` skill
- If multiple languages detected → suggest language-specific notes

### Step 6: Apply

After user confirms:

```bash
codeindex claude-md update
```

This is idempotent and marker-based — repeated runs don't duplicate content.

For user-global `~/.claude/CLAUDE.md`:

```bash
codeindex claude-md update --global
```

### Step 7: Confirm + Next Steps

Print:
- ✅ "CLAUDE.md refreshed to vX.Y.Z"
- Backup location (if `claude-md update` made one)
- Reminder: re-running `pipx upgrade ai-codeindex` may bump version again; re-run this skill after upgrade

## Important Notes

- Always show diff first (`--dry-run`) before applying — user controls the change
- This skill **delegates to the CLI** rather than touching files directly. If `codeindex claude-md update` doesn't exist (older CLI), advise `pipx upgrade ai-codeindex`
- For non-interactive automation, the CLI also accepts `codeindex claude-md update --yes`
