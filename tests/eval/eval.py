#!/usr/bin/env python3
"""Parse run JSONL pairs, LLM-judge quality, emit report.md.

Run after run-batch.sh has populated runs/. Idempotent — re-runs judge.
"""
import json
import subprocess
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
RUN_DIR = SCRIPT_DIR / "runs"
REPORT = SCRIPT_DIR / "report.md"


def parse_run(jsonl_path: Path) -> dict:
    tools = []
    final_text = ""
    result = None
    for line in jsonl_path.read_text().splitlines():
        line = line.strip()
        if not line.startswith("{"):
            continue
        try:
            e = json.loads(line)
        except json.JSONDecodeError:
            continue
        if e.get("type") == "assistant":
            for c in e.get("message", {}).get("content", []):
                if c.get("type") == "tool_use":
                    tools.append({"name": c.get("name"), "input": c.get("input", {})})
                elif c.get("type") == "text":
                    final_text += c.get("text", "")
        elif e.get("type") == "result":
            result = e
    return {
        "tools": tools,
        "final_text": final_text,
        "cost_usd": (result or {}).get("total_cost_usd"),
        "duration_ms": (result or {}).get("duration_ms"),
        "out_tokens": (result or {}).get("usage", {}).get("output_tokens"),
    }


def detect_skill_invoke(tools: list) -> str | None:
    """Return skill name if any tool_use is Skill(codeindex:*)."""
    for t in tools:
        if t.get("name") == "Skill":
            sk = t.get("input", {}).get("skill", "")
            if sk.startswith("codeindex:"):
                return sk
    return None


def judge_quality(prompt: str, a_text: str, b_text: str) -> str:
    """Use claude -p to judge which answer is better."""
    jp = (
        f'Two AI agents answered: "{prompt}"\n\n'
        f"ANSWER A:\n{a_text[:3000]}\n\n"
        f"ANSWER B:\n{b_text[:3000]}\n\n"
        'Which is better for the user? Reply with EXACTLY one of: "A", "B", '
        'or "TIE", followed by one sentence reason. Be strict — if both are '
        'roughly equal, say TIE.'
    )
    res = subprocess.run(
        ["claude", "-p", jp, "--output-format", "text",
         "--no-session-persistence", "--max-budget-usd", "0.15"],
        capture_output=True, text=True, timeout=180,
    )
    return res.stdout.strip().replace("\n", " ")


def main() -> None:
    prompts = []
    for line in (SCRIPT_DIR / "prompts.tsv").read_text().splitlines():
        line = line.rstrip()
        if not line or line.startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) >= 3:
            prompts.append((parts[0], parts[1], parts[2]))

    rows = []
    for pid, prompt, expected in prompts:
        a = parse_run(RUN_DIR / f"{pid}-A.jsonl")
        b = parse_run(RUN_DIR / f"{pid}-B.jsonl")
        a_skill = detect_skill_invoke(a["tools"])
        b_skill = detect_skill_invoke(b["tools"])

        judge = "n/a" if expected == "(none)" else judge_quality(
            prompt, a["final_text"], b["final_text"]
        )

        rows.append({
            "id": pid,
            "expected": expected,
            "a_tools": [t["name"] for t in a["tools"]],
            "b_tools": [t["name"] for t in b["tools"]],
            "b_skill": b_skill or "—",
            "a_cost": a["cost_usd"], "b_cost": b["cost_usd"],
            "a_dur": a["duration_ms"], "b_dur": b["duration_ms"],
            "a_out": a["out_tokens"], "b_out": b["out_tokens"],
            "judge": judge,
        })

    md = ["# codeindex-claude eval — A (no plugin) vs B (with plugin)\n\n"]
    md.append("| id | expected | A tools | B tools | B invoked | A $ | B $ | Δ$ | A dur | B dur | judge |\n")
    md.append("|---|---|---|---|---|---|---|---|---|---|---|\n")
    for r in rows:
        delta = ""
        if r["a_cost"] and r["b_cost"]:
            delta = f"{(r['b_cost'] - r['a_cost']) / r['a_cost'] * 100:+.0f}%"
        a_dur = f"{r['a_dur']/1000:.1f}s" if r["a_dur"] else "—"
        b_dur = f"{r['b_dur']/1000:.1f}s" if r["b_dur"] else "—"
        a_cost = f"${r['a_cost']:.3f}" if r["a_cost"] else "—"
        b_cost = f"${r['b_cost']:.3f}" if r["b_cost"] else "—"
        md.append(
            f"| {r['id']} | {r['expected']} | {','.join(r['a_tools']) or '—'} | "
            f"{','.join(r['b_tools']) or '—'} | {r['b_skill']} | "
            f"{a_cost} | {b_cost} | {delta} | {a_dur} | {b_dur} | "
            f"{r['judge'][:100]} |\n"
        )

    out = "".join(md)
    REPORT.write_text(out)
    print(out)
    print(f"\nWritten: {REPORT}")


if __name__ == "__main__":
    main()
