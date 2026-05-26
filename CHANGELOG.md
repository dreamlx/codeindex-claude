# Changelog

All notable changes to this plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.3] - 2026-05-26

### Changed

- **Skill descriptions refactored to third-person format** per `plugin-dev:skill-development` guidance. All 4 skills (`arch`, `index`, `hooks`, `update-guide`) now open with `"This skill should be used when the user asks to ..."` and list explicit trigger phrases — that's what Claude Code's skill-selection mechanism actually scores. The old imperative form ("Refresh the codeindex section...") was being scored as task description rather than triggering criteria.
- Added explicit `version: 0.1.3` field to each skill's frontmatter.

### Fixed

- Removed non-standard `user_invocable: true` field from `update-guide/SKILL.md`. Skill frontmatter accepts only `name`, `description`, and optional `version` per official plugin-dev guidance — `user_invocable` is not a recognized field, and skills are model+user invocable by default with no opt-out mechanism (`disable-model-invocation` is a *command* frontmatter field, not a skill one).
- Dropped second-person "your" leak in `hooks/SKILL.md` (per `plugin-dev:skill-reviewer` audit).
- Corrected v0.1.0 release notes: minimum required CLI is `ai-codeindex >= 0.25.0` (the version that introduces `codeindex claude-md update` / `affected` subcommands), not `0.24.0` as originally stated. A SessionStart-hook version check will land in v0.1.4.

## [0.1.2] - 2026-05-26

### Fixed

- **Plugin install rejected manifest**: `author: Invalid input: expected object, received string`. The plugin manifest `author` field must be an object `{"name": ..., "email"?: ..., "url"?: ...}`, not a bare string. Changed `"author": "DreamLinx"` → `"author": {"name": "DreamLinx"}`. (Verified all other manifest fields — `repository`, `homepage`, `license`, `keywords` — are already correctly typed per the [manifest schema](https://code.claude.com/docs/en/plugins-reference#plugin-manifest-schema).)

## [0.1.1] - 2026-05-26

### Fixed

- **Plugin install failed** with "source type your Claude Code version does not support". Two spec-compliance bugs found by attempting `/plugin install` for real:
  - Marketplace plugin `source` was `"."` — the relative-path source type **must start with `./`** and point to a subdirectory within the marketplace repo. Restructured to the canonical layout (`plugins/codeindex/` subdir) with `source: "./plugins/codeindex"`, matching the official walkthrough.
  - `hooks/hooks.json` used a flat `{matcher, command}` shape. Correct schema nests `hooks: [{type: "command", command: ...}]` under each matcher entry. Also fixed the SessionStart matcher from `"*"` (invalid) to `"startup|resume|clear"` (valid SessionStart matcher values).

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
- Requires `ai-codeindex >= 0.25.0` (the `codeindex claude-md update` CLI subcommand used by `codeindex:update-guide`). *(Corrected in v0.1.3 — original v0.1.0 release notes incorrectly stated 0.24.0.)*
