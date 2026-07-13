---
name: handoff
description: Write a compact session-handoff document so the next session (or a fresh subagent) can resume work without re-reading everything. Use when ending a work session mid-task, before /clear, or when the conversation has grown long enough that continuing is more expensive than restarting from a summary.
---

# Handoff

Produce a handoff document that lets a cold-start session resume this work at full
speed. Write it to the project root as `HANDOFF.md` (or a path the user names).

Pattern credit: Matt Pocock's `/handoff` (github.com/mattpocock/skills, MIT).
This is an independent re-implementation of the idea.

## Contents (in this order)

1. **Goal** — the task in 1–2 sentences, including what "done" means.
2. **State** — what is already complete and verified, with file paths. Plain
   statements only: "X works, tested via Y", not "X should work".
3. **In flight** — the step that was underway, exactly where it stopped, and why.
4. **Next actions** — an ordered, concrete list the next session can execute
   without re-deriving the plan.
5. **Landmines** — non-obvious constraints, gotchas already hit, decisions already
   made (with the why) so they aren't re-litigated or re-discovered.
6. **Commands** — how to build/test/run what's relevant, verbatim.

## Rules

- Target ≤60 lines. The point is cheap re-briefing; a bloated handoff defeats it.
- Write for a reader with zero conversation context but full repo access — link
  files, don't paste them.
- Facts only. If something is unverified, label it unverified.
- After writing, tell the user the file path and suggest starting the next session
  with: "Read HANDOFF.md and continue."
