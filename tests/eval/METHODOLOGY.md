# Agent-native middleware eval methodology — V0.1

Sink for lessons learned dogfooding codeindex-claude v0.1.4 (2026-05-26).
Intended to be promoted to a portfolio-level asset once a second instance
(loomgraph or IntentSpec) reuses it.

## Why this exists

Plugin development without baseline measurement is cargo cult. v0.1.3
(skill description refactored to third-person) and v0.1.4 (hook version
check + contract CI) were both shipped on theoretical-only justification.

First dogfood attempts revealed:

- **v0.1.3 hypothesis falsified**: precise third-person trigger phrases
  match the user prompt but the agent still falls back to grep — skill
  description is a hint, not a force.
- **Plugin presence ≠ value**: on a simple "where is X" navigation
  prompt, loading the plugin made the agent cost +124%, time +84%,
  output +185% — and the codeindex skill was never invoked.
- **Workflow is destructive without consent**: the index skill runs
  `codeindex init` (4 mutations) before showing the user what it will
  change.

These would have been caught pre-merge if a real A/B harness existed.

## Confounds that broke V0 harness

### C1: user-scope plugin auto-load

`claude plugin install` registers a plugin at **user scope** (or local
scope tied to a project-path). `--plugin-dir` adds an additional plugin;
it does **not** replace or exclude already-installed ones.

`cwd` outside the plugin's project-path does **not** unload the plugin
when the install scope is `user`. The plugin is loaded as long as the
user-level CC config lists it.

→ To make "condition A = no plugin" real, must explicitly:

    claude plugin disable codeindex@codeindex-claude --scope user
    # run A condition
    claude plugin enable  codeindex@codeindex-claude --scope user
    # run B condition (use --plugin-dir to pin to a specific version under test)

### C2: run-to-run variance dominates condition effect

Same prompt + same condition, two consecutive runs:

| prompt | cost run1 | cost run2 | dur run1 | dur run2 |
|---|---|---|---|---|
| hooks_setup A | $0.437 | $0.137 | 65s | 8s |
| arch_simple A | $0.189 | $0.232 | 12s | 22s |

Variance ratios up to 3.2× on cost and 8.4× on duration **within the
same condition**. Single-shot A/B is noise, not signal.

→ N ≥ 3 samples per (prompt × condition) cell. Report median + IQR.
If condition Δ is within the union of A's and B's IQRs, declare "no
signal" — do not ship the change.

### C3: prompt-formulation sensitivity

"where is the SessionStart hook implemented in **this plugin**?" with
cwd=/tmp yields different agent behavior from "where is the
SessionStart hook implemented in **the codeindex plugin at ~/path**?"
— even with identical plugin loading.

→ Prompts must be byte-versioned (hash the literal string). Same hash
across all conditions in a single A/B. Prompt-formulation variants are
a **separate** experiment, not part of baseline.

### C4: `claude -p` headless mode does not support skill workflow

**Hard constraint, not a configuration issue.**

Direct evidence from V0 batch 2 (all 4 codeindex skills):

```
✗ ERROR Skill(codeindex:arch)         is_error=True, content="Execute skill: codeindex:arch"
✗ ERROR Skill(codeindex:index)        is_error=True
✗ ERROR Skill(codeindex:hooks)        is_error=True
✗ ERROR Skill(codeindex:update-guide) is_error=True
```

Hypothesis "permission UI blocks Skill in headless" tested with
`--permission-mode bypassPermissions` — falsified. Bypassing permissions
caused the agent to **skip Skill entirely** and route to `Grep` + `Read`
directly. Skill workflow never ran cleanly under any headless config.

Same prompts in **interactive** mode (manual session, prompt 2 dogfood)
ran the index skill end-to-end: `init` → `scan-all` → `AskUserQuestion`
→ file write. Interactive works; headless does not.

→ **Any A/B harness built on `claude -p` measures "system-prompt
including skill descriptions changes agent tool selection" — it does
NOT measure plugin skill workflow value.** Treat headless metrics as a
proxy for "description influence on top-level tool routing," not as
plugin value measurement.

Real plugin measurement requires one of:
- **tmux + interactive `claude`** with send-keys + capture-pane (brittle
  ANSI parsing, timing-sensitive, permission-UI automation needed)
- **Claude Code SDK** if one with skill support becomes available
- Accept that some plugin classes are effectively un-A/B-testable
  programmatically — fall back to manual fresh-session dogfood

## V1 harness requirements

Before any future plugin/middleware change is shipped:

0. **Pick the right surface for the question** (because of C4):
   - "Does description X improve top-level tool routing?" → `claude -p`
     headless is fine
   - "Does skill workflow X improve task completion?" → must use
     interactive (tmux) or accept manual dogfood
1. **Scope cleanup** — disable user-scope for A condition, re-enable for B
2. **N ≥ 3** samples per cell
3. **Median + IQR + p90** reporting, not raw single numbers
4. **Rubric-based LLM-judge** — not free-form "which is better", but a
   small fixed rubric (e.g. correctness 1–5, completeness 1–5,
   conciseness 1–5). Average two judge runs to reduce judge variance.
5. **Idempotency check** — run the same A/B pair twice the same day,
   confirm Δ falls within IQR. If it doesn't, methodology itself is
   broken and the result can't be trusted.
6. **Per-run cost ceiling** via `--max-budget-usd`

## Cost / time envelope

- V0 (single-shot, 5 prompt × 2 cond): ~$2.5 / batch / ~5 min
- V1 (N=3, 5 prompt × 2 cond = 30 runs): ~$8 / batch / ~15 min
- Quarterly across 3 portfolio instances: ~$100/year

This is the price of evidence-based middleware development.

## What NOT to do

- Don't ship description / trigger / workflow changes without A/B (the
  v0.1.3 lesson)
- Don't conflate "agent reasoned about plugin" with "agent invoked
  plugin" — only the Skill tool_use entry counts
- Don't trust a single batch's numbers — variance can flip the sign
- Don't write methodology as a one-instance artifact — when a second
  middleware project reuses this, abstract to a portfolio repo

## V0 artifacts (preserved as confound-bug evidence)

- `prompts.tsv` — 5 prompts (4 codeindex-relevant + 1 noise control)
- `run-batch.sh` — runner (broken: doesn't disable user-scope plugin)
- `eval.py` — JSONL parser + rubric-free judge
- `runs/` (gitignored) — raw stream-json from two batches

Both batches are **invalid as quality measurements**. They are valid as
demonstrations of C1 and C2. Re-run with V1 harness before drawing any
plugin-quality conclusions.

## Status

- V0 documented (this file)
- V1 not built — trigger is the next plugin/middleware change that
  requires evidence to ship
- Promotion to portfolio repo deferred until 2nd instance reuses
