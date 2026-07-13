# Tiered Claude / Claude Code Configuration for Quality + Token Efficiency

Target: research + SWE. Core principle: **spend frontier tokens on judgment, cheap tokens on volume.** Most token consumption in a session is execution (writing files, editing, running tests), not planning. Route planning/architecture/hard-debug to a strong model; route mechanical execution to a cheap model.

All facts below verified against Claude Code official docs (`code.claude.com/docs/en/model-config`, July 2026) unless flagged as community pattern.

---

## 1. Model tiers and current price (Jul 2026)

| Model | Input $/MTok | Output $/MTok | Role in this scheme |
|---|---|---|---|
| Fable 5 | 10 | 50 | Optional top orchestrator for very long, multi-sitting tasks |
| Opus 4.8 | 5 | 25 | Planner / reasoner / architect / hard debug |
| Sonnet 5 (intro, ≤Aug 31 2026) | 2 | 10 | Executor: code gen, edits, tests, boilerplate |
| Sonnet 5 (standard, post-Aug 31) | 3 | 15 | Executor |
| Haiku 4.5 | 1 | 5 | Trivial lookups, formatting, log parsing, background |

Cache multipliers (all models): 5-min cache write 1.25×, 1-hour write 2×, cache read 0.1× of base input.

Output tokens dominate cost. Every plan Fable writes costs ~5x the same text from Sonnet. On a Claude.ai subscription, a Fable session burns ~2x an Opus session and several times a Sonnet session against weekly limits. Reported savings from correct tiering: ~40% (1 Opus orchestrator + 4 Sonnet workers vs 5 Opus) up to 5–10x (Opus orchestrator + Haiku/Sonnet subagents) with no meaningful quality loss on well-specified work.

**Decision rule:** default to Opus-as-planner + Sonnet-as-executor. Only escalate the top tier to Fable when a task genuinely spans more than one sitting and needs sustained autonomous investigation. Fable as your everyday main model is the most common overspend.

---

## 2. The three patterns (in increasing complexity)

### Pattern A — `opusplan` (zero-setup, use this first)
Built-in mode. Opus runs during plan mode (architecture, reasoning); on exiting plan mode it auto-switches to Sonnet for execution.

```
/model opusplan
```
- Plan-mode Opus inherits the same context window as the `opus` setting (incl. 1M auto-upgrade on tiers that grant it; force both phases with `opusplan[1m]`).
- This is the single highest-leverage change. It captures ~80% of the benefit for ~0% of the config effort.

### Pattern B — Orchestrator + subagents (delegation)
Main session (Opus, or Fable for very large tasks) stays lean and delegates:
- **deep-reasoner** subagent → Opus → architecture, algorithm design, complex debugging. Returns a *concise conclusion*, not its full reasoning trace (keeps orchestrator context small).
- **fast-worker** subagent → Sonnet → boilerplate, tests, formatting, mechanical edits.

Subagents run in isolated context windows; only their summary returns to the parent. This is both a cost lever (cheap model does volume) and a context-hygiene lever (parent context stays small → cheaper per turn, less degradation). This three-tier version (Fable lead / Opus reasoner / Sonnet worker) is a **community pattern**, not officially prescribed; Anthropic's own documented guidance is the same spirit (strong plans, cheap executes) via `opusplan`.

### Pattern C — Advisor (hybrid, mid-task escalation)
`advisorModel` / `--advisor` lets a cheaper main model (Sonnet/Haiku) consult a stronger model (Opus/Fable) *mid-task* when it hits something hard, instead of switching at the plan boundary. Use when work is mostly mechanical but occasionally hits a hard decision. See `code.claude.com/docs/en/advisor`.

---

## 3. Concrete configuration

### 3.1 User settings — `~/.claude/settings.json`
Sensible global defaults. Per-project settings override.

```json
{
  "model": "opusplan",
  "effortLevel": "high",
  "env": {
    "CLAUDE_CODE_SUBAGENT_MODEL": "sonnet"
  }
}
```
Notes:
- `CLAUDE_CODE_SUBAGENT_MODEL` sets the default model for *all* subagents and overrides per-agent frontmatter. Set it to `sonnet` to force cheap execution globally; set to `inherit` to let each agent's own `model` field decide. **Pick one philosophy — do not fight your own frontmatter.** If you want per-agent control (recommended, see 3.2), leave this unset or `inherit`.
- `effortLevel` accepts `low|medium|high|xhigh` in settings (`max`/`ultracode` are session-only). `high` is the model default for Fable 5 / Opus 4.8 / Sonnet 5 and the right baseline. Reserve `xhigh`/`max` for problems where you've confirmed extra reasoning changes the output — max effort burns tokens for frequently-identical results.
- `CLAUDE_CODE_EFFORT_LEVEL` env var beats all other effort settings if you need a hard override.

Recommended: leave `CLAUDE_CODE_SUBAGENT_MODEL` **unset** and control models per-agent via frontmatter (below). It's more explicit and lets a reasoning subagent legitimately use Opus.

### 3.2 Subagents — `.claude/agents/*.md`

`.claude/agents/deep-reasoner.md`
```markdown
---
name: deep-reasoner
description: Use for reasoning-heavy phases — architecture, algorithm design, complex/root-cause debugging, tradeoff analysis. Think thoroughly, return a concise actionable conclusion, not the full trace.
model: opus
effort: high
---
You are the deep reasoning specialist. Investigate thoroughly. Produce:
1. The decision/answer.
2. 3-6 bullet justification.
3. Concrete next actions the orchestrator can hand to an executor.
Do NOT write production code. Do NOT dump your full reasoning; the orchestrator's context is scarce.
```

`.claude/agents/fast-worker.md`
```markdown
---
name: fast-worker
description: Use for mechanical work — boilerplate, tests, formatting, simple/localized edits, applying a spec. Execute efficiently, do not re-litigate design.
model: sonnet
effort: medium
---
You are the executor. Implement exactly the provided spec. If the spec is ambiguous or you hit a genuine design fork, STOP and report back rather than guessing. Keep responses terse.
```

Notes:
- `model` field accepts `sonnet|opus|haiku|fable|inherit` or a pinned ID (`claude-opus-4-8`). `inherit` (the default) = same as main session.
- Documented resolution order: `CLAUDE_CODE_SUBAGENT_MODEL` env var > per-invocation `model` parameter > agent frontmatter `model` > `inherit`.
- `effort` in subagent frontmatter overrides session effort while that agent runs (but not the `CLAUDE_CODE_EFFORT_LEVEL` env var).
- New agent files are picked up only on session restart.
- **Known bug (verify on your version):** as of 2026-07-12, [#43869](https://github.com/anthropics/claude-code/issues/43869) (all routing mechanisms silently resolve to the parent model) is still **open**, while [#26179](https://github.com/anthropics/claude-code/issues/26179) (default subagents to Sonnet) was closed as not-planned. The current docs describe the working precedence chain above, which conflicts with #43869 — likely fixed on newer versions, but confirm on yours: run the reasoner, check the model label in output. If broken, fall back to `opusplan` (Pattern A) which is reliable, or pin models via env vars.

### 3.3 `CLAUDE.md` — orchestration instructions (per project root)

```markdown
# Orchestration
You are the orchestrator. Plan, decompose, synthesize. Keep your own context lean —
delegate rather than doing mechanical work yourself.
- Reasoning-heavy phases (architecture, algorithm design, hard debugging) -> deep-reasoner (Opus).
- Mechanical work (boilerplate, tests, formatting, localized edits) -> fast-worker (Sonnet).
- Show the plan before executing; let me redirect before tokens are spent.
- For high-stakes decisions, run deep-reasoner twice with different framings and synthesize.

# Repo facts (keep short — this file is read every session, every token counts)
- Language / framework: ...
- Test command: ...
- Lint/format command: ...
- Architectural invariants the executor must not violate: ...
```
Keep `CLAUDE.md` short and factual. It loads into every session's context; bloat here is a recurring tax on every turn. Put repo commands, invariants, and conventions — not prose.

---

## 4. Workflow recipes

**SWE — default coding session**
1. `/model opusplan`, `/effort high`.
2. Enter plan mode (Opus). State goal + constraints + relevant files. Review the plan.
3. Exit plan mode → Sonnet executes.
4. Escalate to `deep-reasoner` only when execution hits a genuine design/debug wall.

**SWE — large multi-sitting build (refactor, new subsystem)**
1. Main model Fable (`/model fable`, or `best` alias) as orchestrator.
2. Delegate reasoning → deep-reasoner (Opus), volume → fast-worker (Sonnet).
3. Prompt like a tech lead: `Goal / Context / You're the lead. Delegate reasoning to deep-reasoner, grunt work to fast-worker. Plan first, then execute.`

**Research — literature/data synthesis**
- Main model Opus for the reasoning/synthesis you actually read.
- Delegate wide, shallow gathering (fetching, extracting, log/table parsing) to Sonnet or Haiku subagents — high volume, low judgment.
- For heavy CS/ML reasoning (proof sketches, method comparison) use Opus or `deep-reasoner`; Fable only if the task is genuinely multi-hour and autonomous.

---

## 5. Bio-research gotcha (directly relevant to you)

Fable 5 runs safety classifiers on **cybersecurity, biology & chemistry, distillation, and frontier-LLM-development** content. A flagged request is **re-run on Opus 4.8 with a notice shown in the transcript** (it is *not* silent — an earlier revision of this doc said otherwise), and the session then **stays on Opus until you run `/model fable` again**. Anthropic reports >95% of Fable sessions involve no fallback; a fallback is by design better than an outright refusal. Your workspace context (CLAUDE.md, git status, a biotech repo) can still trip this early in a session.

Implications:
- Notices are easy to miss in a long transcript. If Fable "feels different" mid-project, check `/model` before debugging your setup — you may have been rerouted.
- For biology/aptamer/synbio work, don't assume you're paying Fable rates after a flag; you may be on Opus (cheaper — sometimes a feature).
- To enable clean auto-fallback on third-party providers (Bedrock/Vertex/Foundry), set `ANTHROPIC_DEFAULT_FABLE_MODEL` and `ANTHROPIC_DEFAULT_OPUS_MODEL` to your provider's model IDs; otherwise flagged requests hard-refuse instead of falling back.
- Caveat from the field: one user-filed report ([#67246](https://github.com/anthropics/claude-code/issues/67246), unconfirmed) says `/model fable` sometimes fails to switch back ("Kept model as Opus 4.8"). If that hits you, restart the session.

---

## 6. Token-efficiency checklist (independent of tiering)

- **Context hygiene beats model choice.** Cost scales with tokens per turn; a bloated context makes every turn on every model more expensive. Delegate to subagents (isolated context, only summary returns), `/clear` between unrelated tasks, keep CLAUDE.md lean.
- **Effort discipline.** `high` default; escalate deliberately. `ultrathink` keyword in a single prompt gives deeper reasoning for that turn only without raising the session effort (cheaper than bumping `/effort`). "think hard" etc. are *not* recognized keywords — only `ultrathink`.
- **Plan before executing** so you catch wrong approaches before Sonnet spends tokens implementing them.
- **Pin executor to cheap, planner to strong** — never invert.
- **Don't run everything through Fable.** It's the most common overspend; reserve for multi-sitting autonomy.
- **Sometimes-needed know-how belongs in a skill, not CLAUDE.md.** A skill costs ~one description line until invoked; CLAUDE.md is charged every turn. See [`skills-guide.md`](skills-guide.md).
- **MCP servers are near-free at rest** (Tool Search defers schemas by default), but a capable CLI via Bash is still cheaper and simpler. See [`mcp-guide.md`](mcp-guide.md).

---

## 7. Rollout / verification

1. Add the `settings.json` above (start with `opusplan`, no subagents). Use for a few real tasks.
2. Add the two subagents + CLAUDE.md. **Verify model routing actually works** (run deep-reasoner, confirm the model label). If routing is bugged on your version, stay on `opusplan`.
3. Measure: check `/cost` (or subscription usage) across a comparable task before/after. Confirm the split reduces spend without quality regression.
4. Only after B is stable, experiment with Fable-as-orchestrator for genuinely large tasks and the `advisor` hybrid for mostly-mechanical work.

Minimum viable version if you do nothing else: **`/model opusplan` + `/effort high` + a lean CLAUDE.md.**

---

## Sources
- [Claude Code — Model configuration (official docs)](https://code.claude.com/docs/en/model-config)
- [Claude Code — Skills (official docs)](https://code.claude.com/docs/en/skills) · [Sub-agents](https://code.claude.com/docs/en/sub-agents) · [MCP](https://code.claude.com/docs/en/mcp)
- [Claude Fable 5 / Mythos 5 announcement (fallback behavior)](https://www.anthropic.com/news/claude-fable-5-mythos-5)
- [Anthropic — Code execution with MCP (token-efficiency pattern)](https://www.anthropic.com/engineering/code-execution-with-mcp)
- [Anthropic — April 23 postmortem (the real story behind "nerfed")](https://www.anthropic.com/engineering/april-23-postmortem)
- [Claude Code model configuration — Help Center](https://support.claude.com/en/articles/11940350-claude-code-model-configuration)
- [Fable 5 as Orchestrator, Sonnet as Executor — Data Science Dojo](https://datasciencedojo.com/blog/claude-code-fable-5-orchestrator-workflow/)
- [Save Tokens with Opus Plan Mode — MindStudio](https://www.mindstudio.ai/blog/claude-code-opus-plan-mode-token-savings)
- [Opus as Adviser to Sonnet/Haiku (Advisor strategy) — MindStudio](https://www.mindstudio.ai/blog/claude-code-advisor-strategy-opus-sonnet-haiku)
- [Smart Orchestrator directing cheaper sub-agents — MindStudio](https://www.mindstudio.ai/blog/smart-orchestrator-cheaper-sub-agent-models-claude-code)
- [Claude Code Agents / parallel-session cost — CloudZero](https://www.cloudzero.com/blog/claude-code-agents/)
- [Subagents default-to-Sonnet issue #26179](https://github.com/anthropics/claude-code/issues/26179) · [Subagent model routing bug #43869](https://github.com/anthropics/claude-code/issues/43869)
