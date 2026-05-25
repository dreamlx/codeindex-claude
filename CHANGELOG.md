# Changelog

All notable changes to this plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-05-25

**Initial release** — bootstrapping the plugin distribution per
[codeindex ADR-006](https://github.com/dreamlx/codeindex/blob/master/docs/architecture/adr/006-distribution-architecture-split.md).

### Added

- Plugin manifest at `.claude-plugin/plugin.json`
- 4 skills under `skills/`:
  - `codeindex:arch` — code architecture queries via `README_AI.md`
  - `codeindex:index` — repository indexing walkthrough (`codeindex scan-all`)
  - `codeindex:hooks` — git post-commit hook setup walkthrough
  - `codeindex:update-guide` — `CLAUDE.md` refresh walkthrough
- `SessionStart` hook at `hooks/check-codeindex.sh` that verifies the `codeindex` CLI is on `PATH` and prints an actionable install hint if not
- `marketplace.json` so this repo doubles as a private single-plugin marketplace
- `README.md` with prerequisite + install instructions

### Notes

- Skill contents are ported from the codeindex repo's `skills/src/` and `.claude/skills/` directories, with `mo-` prefix dropped (plugin namespace handles disambiguation: `codeindex:arch` etc.).
- Requires `ai-codeindex >= 0.24.0` (the `codeindex claude-md update` CLI subcommand used by `codeindex:update-guide`).
