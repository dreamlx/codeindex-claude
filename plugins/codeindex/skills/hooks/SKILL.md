---
name: hooks
description: This skill should be used when the user asks to "set up auto-update", "install codeindex hooks", "auto-update README_AI.md", "keep docs in sync", or wants Git hooks that automatically refresh codeindex README_AI.md files when code changes are committed.
version: 0.1.3
---

# codeindex:hooks — Auto-Update Hooks Setup

Set up Git hooks so `README_AI.md` files automatically refresh when code changes are committed.

> **Prereq**: `codeindex` CLI must be on PATH. If not, install with `pipx install ai-codeindex`.

## How It Works

**Architecture**: Thin wrapper shell script → Python logic in the installed `codeindex` package (auto-upgradeable via `pipx upgrade ai-codeindex`).

When a developer commits code changes:

1. Shell wrapper skips doc-only commits (loop guard), activates venv if present
2. Delegates to `codeindex hooks run post-commit` (Python entry point)
3. `codeindex affected --json` analyzes the change scope
4. `codeindex scan` regenerates structural README_AI.md for affected directories
5. Updated README_AI.md files are auto-committed

**Key**: Hook only updates structural content. AI blockquote descriptions
(module purpose) are not regenerated per-commit — run `codeindex scan-all --ai`
to refresh those.

**Upgrade**: `pipx upgrade ai-codeindex` auto-updates hook logic.
No need to reinstall hooks after package upgrade.

## Prerequisites Check

```bash
# 1. codeindex must be installed
which codeindex || echo "Not installed. Run: pipx install ai-codeindex"

# 2. Project must be a git repository
git rev-parse --is-inside-work-tree

# 3. Project must have codeindex config
cat .codeindex.yaml 2>/dev/null || codeindex init --yes
```

## Setup Workflow

### Step 1: Check Current Hook Status

```bash
codeindex hooks status
```

Shows which hooks are installed (pre-commit, post-commit, pre-push).

### Step 2: Install Post-Commit Hook

```bash
codeindex hooks install post-commit        # recommended
# or:
codeindex hooks install --all              # post-commit + pre-commit + pre-push
```

If a custom post-commit hook already exists, it's backed up automatically.

### Step 3: Configure Hook Behavior

Edit `.codeindex.yaml`:

```yaml
hooks:
  post_commit:
    enabled: true
    mode: auto          # auto | sync | async | prompt | disabled
    max_dirs_sync: 2    # Threshold for sync vs async in auto mode
```

**Modes**:

| Mode | Behavior |
|------|----------|
| `auto` | Smart: sync for small changes (≤ `max_dirs_sync`), async otherwise |
| `sync` | Always wait for update to complete before returning |
| `async` | Always run in background (non-blocking) |
| `prompt` | Show notification but don't auto-update; user runs `codeindex affected --update` manually |
| `disabled` | Hook installed but inactive |

### Step 4: Verify

```bash
codeindex hooks status

# Test it:
echo "# test" >> some_file.py
git add some_file.py && git commit -m "test: verify auto-update hook"
git log --oneline -2   # should show "docs: auto-update README_AI.md for <hash>"
```

### Step 5: Generate Initial Index (if not done)

Hook only updates *existing* README_AI.md files. Generate the initial index first:

```bash
codeindex scan-all
git add -A && git commit -m "docs: initial README_AI.md generation"
```

## Uninstalling

```bash
codeindex hooks uninstall post-commit      # restores any backup
codeindex hooks uninstall --all
```

## Upgrading

Usually not needed — `pipx upgrade ai-codeindex` updates the Python logic the shell wrapper invokes.

Only if release notes say "reinstall hooks":

```bash
codeindex hooks install post-commit --force
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Hook not triggering | `codeindex hooks status` — must show "installed" |
| Infinite commit loop | Shouldn't happen (wrapper skips doc-only commits). If it does, `codeindex hooks uninstall post-commit` |
| Hook too slow | `mode: async` in `.codeindex.yaml` |
| Want manual control | `mode: prompt` — notification only, run `codeindex affected --update` yourself |
| Virtual env not found | Ensure `.venv/` or `venv/` exists at project root, or hook will still try `codeindex` from PATH |
| Old hook style | `codeindex hooks install post-commit --force` upgrades to thin wrapper |

## Advanced: CLAUDE.md Integration

Add this snippet to the project's CLAUDE.md so Claude Code agents know about the auto-update:

```markdown
## Documentation Auto-Updates

This project uses codeindex with post-commit hooks.
README_AI.md files auto-update when code changes.

- **Read README_AI.md first** before exploring source code
- After modifying code, README_AI.md updates on next commit
- To manually update: `codeindex scan ./path/to/dir`
- To check coverage: `codeindex status`
```

(Or use the `codeindex:update-guide` skill to refresh your CLAUDE.md to the latest template.)
