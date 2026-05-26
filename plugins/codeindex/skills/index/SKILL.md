---
name: index
description: This skill should be used when the user asks to "index this project", "generate code index", "scan codebase", "create AI documentation", or wants README_AI.md files generated for a codebase so it becomes searchable by AI agents. Wraps the codeindex CLI.
version: 0.1.3
---

# codeindex:index — Repository Indexing

Generate AI-friendly index files (`README_AI.md`) for codebases using the codeindex CLI.

> **Prereq**: `codeindex` CLI must be on PATH. If not, install with `pipx install ai-codeindex` (plugin SessionStart hook surfaces this).

## Workflow

### Step 0: Surface What Will Change

Before initializing, enumerate what `codeindex init` will mutate so the user can confirm:

```bash
ls .codeindex.yaml 2>/dev/null || echo "(no .codeindex.yaml — will be created)"
ls README_AI.md   2>/dev/null || echo "(no README_AI.md — will be created at repo root)"
grep -l codeindex CLAUDE.md   2>/dev/null || echo "(no codeindex section in CLAUDE.md — will be injected)"
grep README_AI.md .gitignore  2>/dev/null || echo "(.gitignore will get README_AI.md added)"
```

`codeindex init` creates / modifies up to **4 files**:

- `.codeindex.yaml` (configuration)
- `.gitignore` (adds `README_AI.md`)
- `CLAUDE.md` (injects `## codeindex` section)
- `README_AI.md` (empty stub at repo root)

**If any of those matter to the user, ask before proceeding** (e.g. user already has a hand-maintained CLAUDE.md, or wants `README_AI.md` git-tracked). Only skip the confirmation if the repo is clearly fresh or the user has explicitly consented.

### Step 1: Initialize

```bash
codeindex init --yes
```

`--yes` for non-interactive default config (CI-friendly). Only run after Step 0 surfaces the mutation set and the user has consented.

### Step 2: Review Configuration

```bash
cat .codeindex.yaml
```

Key settings to verify:
- `languages` — Detected programming languages (python, java, php, swift, etc.)
- `include` — Directories to scan
- `exclude` — Patterns to skip
- `ai_command` — AI CLI for `--ai` mode (defaults to claude haiku)

### Step 3: Preview Indexable Directories

```bash
codeindex list-dirs
```

### Step 4: Scan

```bash
# Structural-only (fast, no AI calls):
codeindex scan-all

# Structural + AI-enriched blockquote descriptions (cache-aware):
codeindex scan-all --ai

# Force re-enrich every dir, ignoring cache:
codeindex scan-all --ai --retry-all

# Single dir:
codeindex scan ./src/module
codeindex scan ./src/module --ai
codeindex scan ./src/module --ai --dry-run   # preview prompt only
```

### Step 5: Verify Coverage

```bash
codeindex status
```

### Step 6 (Optional): Set Up Auto-Updates

If user wants README_AI.md to stay in sync on commit, hand off to the `codeindex:hooks` skill:

> "Want READMEs to auto-update when you commit code? Use the `codeindex:hooks` skill to set up the post-commit hook."

## Scan Modes Cheat Sheet

| Mode | Command | When |
|------|---------|------|
| Auto (default) | `codeindex scan-all` | Structural + AI enrichment if `ai_command` configured |
| Structural-only | `codeindex scan-all --no-ai` | Zero AI cost; fastest |
| Re-enrich all | `codeindex scan-all --ai --retry-all` | After prompt or model changes |
| Single dir | `codeindex scan ./dir --ai` | Deep AI README for one directory |

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `AI CLI timeout` | `codeindex scan ./dir --ai --timeout 180` |
| `AI not configured` | Use `codeindex scan-all` (structural mode) — `ai_command` is optional |
| Want to inspect AI prompt | `codeindex scan ./dir --ai --dry-run` |
| Missing language parser | `pipx inject ai-codeindex tree-sitter-<lang>` |
| Rate limit hit mid-scan | Just re-run `codeindex scan-all --ai` — Phase 2 is idempotent, only failed dirs hit AI again |

## Post-Indexing Recommendations

1. Commit `README_AI.md` files for team/AI sharing (or add to `.gitignore` if you regenerate them per developer — `codeindex init` auto-adds this).
2. Set up git hooks for auto-updates (use the `codeindex:hooks` skill).
3. Add to your project's `CLAUDE.md`: "Read README_AI.md before modifying code."
