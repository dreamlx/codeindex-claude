# codeindex-claude

Claude Code plugin that brings the [codeindex](https://github.com/dreamlx/codeindex) CLI into your Claude Code workflow as a set of skills.

## Prerequisites

This plugin **requires the `codeindex` CLI on your `PATH`**. The plugin's skills shell out to it.

```bash
pipx install ai-codeindex
```

(If you don't have `pipx`: `python3 -m pip install --user pipx && pipx ensurepath`.)

The plugin's `SessionStart` hook will warn you if `codeindex` isn't found.

## What's in the plugin

Four skills (auto-namespaced under the plugin):

| Skill | Invoked when | What it does |
|---|---|---|
| `codeindex:arch` | User asks about project structure, "where is X implemented", "how does module Y work" | Reads `README_AI.md` index files to answer architecture questions |
| `codeindex:index` | User asks to index/scan a project, generate documentation | Walks user through `codeindex init` → `scan-all` setup |
| `codeindex:hooks` | User asks to auto-update docs on commit, set up git hooks | Walks user through `codeindex hooks install` and `.codeindex.yaml` hook config |
| `codeindex:update-guide` | User wants to refresh `CLAUDE.md` to latest codeindex guidance | Delegates to `codeindex claude-md update` with project-aware suggestions |

Plus one SessionStart hook that verifies `codeindex` is on `PATH`.

## Installation

### Option 1: Via this repo as a private marketplace (current)

```bash
/plugin marketplace add dreamlx/codeindex-claude
/plugin install codeindex@codeindex-claude
```

### Option 2: Via the official community marketplace (planned)

Once accepted into `anthropics/claude-plugins-community`:

```bash
/plugin install codeindex@claude-community
```

### Option 3: Local development

Clone this repo and run Claude Code with `--plugin-dir`:

```bash
git clone https://github.com/dreamlx/codeindex-claude
claude --plugin-dir ./codeindex-claude/plugins/codeindex
```

Note `--plugin-dir` points at the **plugin directory** (the one containing `.claude-plugin/plugin.json`), i.e. `plugins/codeindex`, not the repo root. Use `/reload-plugins` to hot-reload after editing files. This local-dir path is the recommended loop for developing/testing the plugin — it bypasses the marketplace clone entirely.

## Updates

```bash
/plugin marketplace update codeindex-claude
/plugin update codeindex@codeindex-claude
```

The CLI itself is updated independently via `pipx upgrade ai-codeindex`.

> **If an update doesn't seem to take** (you still see old behavior after `marketplace update`): Claude Code's local marketplace clone can stay pinned at an old commit even when `update` reports success. Force-refresh the clone:
> ```bash
> git -C ~/.claude/plugins/marketplaces/codeindex-claude pull --ff-only
> ```
> then retry `/plugin update`. The nuclear option is `/plugin marketplace remove codeindex-claude` + `/plugin marketplace add dreamlx/codeindex-claude` (this also uninstalls then needs reinstall of the plugin).

## Uninstall

```bash
/plugin uninstall codeindex@codeindex-claude
```

Removing the plugin does NOT uninstall the `ai-codeindex` CLI — that's `pipx uninstall ai-codeindex`.

## Architecture

This plugin is the Claude-Code-facing layer of a deliberate two-artifact split (see [codeindex ADR-006](https://github.com/dreamlx/codeindex/blob/master/docs/architecture/adr/006-distribution-architecture-split.md)):

- **`ai-codeindex`** (PyPI) — the Python CLI. Pure tool, zero Claude Code coupling. Cursor / Continue / bare-CLI users install only this.
- **`codeindex-claude`** (this repo) — Claude Code skills + hooks. Installs / updates / uninstalls cleanly via the platform's plugin mechanism, no `~/.claude/` mutation magic.

## License

MIT. See [LICENSE](LICENSE).
