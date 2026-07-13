---
name: tiered-delegation
description: Decide which model tier should do a piece of work, then delegate it. Use at the start of any multi-step task, before doing bulk mechanical work in the main session, or when a hard design/debug question appears mid-task. Encodes the DauctaurClaude rule — spend frontier tokens on judgment, cheap tokens on volume.
---

# Tiered delegation

You are the orchestrator. Keep your own context lean; route work to the right tier
instead of doing everything in the main session.

## Routing table

| Work | Route to | Why |
|---|---|---|
| Architecture, algorithm design, root-cause debugging, tradeoff analysis | `deep-reasoner` (Opus) | Judgment-heavy; isolated context returns only the conclusion |
| Boilerplate, tests, formatting, localized edits, applying a written spec | `fast-worker` (Sonnet) | Volume work; Sonnet output is ~5x cheaper than Opus |
| Fetching docs/repos/pages, extracting facts, verifying claims | `scraper-researcher` (Sonnet) | Wide + shallow; keeps page dumps out of the main context |
| Synthesis of subagent results, plan decisions, user communication | main session | This is the judgment the strong model is paid for |

## Rules

1. **Plan before executing.** Show the plan and let the user redirect before tokens
   are spent implementing the wrong thing.
2. **Delegate in parallel** when subtasks are independent — one message, multiple
   Agent calls.
3. **Specs down, summaries up.** Give workers a precise spec; require a distilled
   result, never a full trace or page dump.
4. **Don't re-litigate downstream.** Workers execute the spec; genuine design forks
   come back to the orchestrator instead of being guessed at.
5. **Effort discipline.** Stay at `high`; escalate to `xhigh`/`max` only where extra
   reasoning demonstrably changes the output. `ultrathink` in a single prompt deepens
   that turn only.
6. **Context hygiene beats model choice.** `/clear` between unrelated tasks; keep
   CLAUDE.md short — it is a recurring per-turn tax.
