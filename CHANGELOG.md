# Changelog

All notable changes to this plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.6] - 2026-05-26

### Removed

- **`update-guide` skill** — Phase J data shows CLAUDE.md tool-selection guide injection actively hurts quality (0.83 → 0.67). This skill's entire raison d'être was running `codeindex claude-md update` to inject a codeindex教程 into `CLAUDE.md` — proven net-negative. CLI command `codeindex claude-md update` is preserved for users who manually manage `CLAUDE.md`; the plugin no longer promotes that workflow.
- **`hooks/SKILL.md` — "Advanced: CLAUDE.md Integration" section (was lines 135–151)** — same Phase J evidence. Telling agents to "Read `README_AI.md` first" via `CLAUDE.md` injection over-constrains. Benchmark WITH `README_AI.md` (no `CLAUDE.md` guide) already won (-28% token / -19% time) — file presence alone is sufficient.

### Changed

- **`index/SKILL.md`** — added Step 0 "Surface What Will Change" with explicit enumeration of the 4 files `codeindex init` mutates (`.codeindex.yaml`, `.gitignore`, `CLAUDE.md`, `README_AI.md`). Addresses prompt-2 dogfood finding: `init --yes` was modifying 4 files without surfacing the mutation set. Skill now requires the agent to disclose mutations before applying.

## [0.1.5] - 2026-05-26

### Removed

- **`arch` skill** — benchmark + dogfood + Phase J data show **0 marginal value**. The codeindex benchmark's `-28% token / -19% time` win was measured **without any skill loaded**, only with `README_AI.md` files present — agent reads them spontaneously. `arch/SKILL.md` teaches that same workflow, so its marginal contribution to the win is zero. Dogfood `prompt 1` directly observed: `arch` loaded but the agent chose `Grep` over `Skill(codeindex:arch)` despite the description's trigger phrase matching exactly. Phase J (a benchmark side experiment) also showed description-layer invocation guides **hurt** quality (0.83 → 0.67). Removing 0-value skill is hygiene, not new investment — consistent with the v0.1.4 frozen philosophy.

### Added

- **`tests/eval/` — V0 eval harness + `METHODOLOGY.md`** documenting **four** confounds caught during first dogfood attempts. V0 harness preserved as evidence of measurement bugs, **not as quality data**. V1 design requirements specified for future plugin changes.
- **C4 (hard constraint)**: `claude -p` headless mode returns `is_error=True` for every Skill invocation regardless of `--permission-mode` setting. `bypassPermissions` causes the agent to skip Skill entirely and fall back to `Grep`/`Read`. Interactive `claude` runs skills end-to-end. Implication: any `claude -p`-based harness measures "system-prompt skill descriptions changing tool routing", **not** plugin skill workflow value. To measure workflow, use tmux + interactive `claude` (brittle ANSI parsing) or accept manual dogfood.

### Retroactive notes on prior releases (calibration signal)

- **v0.1.3 (skill description third-person refactor) — unmeasured cargo cult.** First dogfood batch falsified the working hypothesis: precise third-person trigger phrases matching the user prompt do **not** force the agent to invoke the skill. Description is a hint, not a force. Net measurable impact on `arch_simple` prompt: agent still chose `Grep` over `Skill(codeindex:arch)`.
- **v0.1.4 (hook version check + contract CI) — production-side only.** Both improvements verify the plugin doesn't break itself; neither was shown to improve consumer-side metrics. First dogfood showed plugin presence on `arch_simple` cost **+124%** and time **+84%** vs no-plugin baseline, with the codeindex skill never invoked. Net per-prompt regression on simple navigation.
- **Implication**: future skill/hook/workflow changes block on V1 harness output. See `tests/eval/METHODOLOGY.md`. Honest value positioning: codeindex delivers efficiency (token/time at equal quality), not comprehension/correctness; plugin is "user-facing discovery surface", not invocation engineering.

## [0.1.4] - 2026-05-26

### Added

- **CLI version check in SessionStart hook**. `check-codeindex.sh` parses `codeindex --version` and warns when the installed CLI is below `MIN_CLI_VERSION="0.25.0"` — the floor for `codeindex claude-md` / `affected` subcommands the plugin skills depend on. Non-blocking warning, matches the existing "not on PATH" behavior.
- **Contract CI** (`.github/workflows/contract.yml`): on every push and PR, installs `ai-codeindex` from `git+https://github.com/dreamlx/codeindex.git@develop` and runs `tests/contract/check-commands.sh`, which `--help`-tests every CLI subcommand the plugin skills reference (14 commands across `scan`, `claude-md`, `hooks`, etc.). Catches plugin↔CLI drift at PR review time rather than in user shells.
- **Contract whitelist** (`tests/contract/expected-commands.txt`): manually curated list of CLI subcommands the plugin depends on. Adding a new CLI call to a skill requires touching this file too — intentional friction to force review of the contract.

### Notes

- Tagged at commit `402b6dd` after `ai-codeindex 0.25.0` reached GA (PyPI 2026-05-26T06:34:13Z, GitHub release 06:34:18Z).
- ADR reference: this implements the "engine vs reach layer" pattern documented in [codeindex ADR-006](https://github.com/dreamlx/codeindex/blob/master/docs/architecture/adr/006-distribution-architecture-split.md) — the version check and contract test are the *reach layer* (plugin) verifying it can still drive the *engine* (CLI).

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
