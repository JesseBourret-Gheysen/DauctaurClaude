---
name: grill-first
description: Interrogate a request before writing any code. Use at the start of any non-trivial implementation task — ask clarifying questions about scope, constraints, edge cases, and success criteria until the spec is unambiguous, then restate the agreed plan. Prevents the most expensive failure mode - confidently building the wrong thing.
---

# Grill first

Before implementing anything non-trivial, interview the requester. A wrong-direction
build costs far more tokens (and human time) than a round of questions.

Pattern credit: Matt Pocock's `/grill-me` (github.com/mattpocock/skills, MIT).
This is an independent re-implementation of the idea.

## Procedure

1. **Read first.** Skim the relevant code/docs so questions are informed, not generic.
2. **Ask in batches** (use AskUserQuestion where available, max ~4 per round):
   - **Scope:** what is explicitly in and out? What should NOT change?
   - **Constraints:** compatibility, performance, style, dependencies, deadlines.
   - **Edge cases:** empty/huge inputs, concurrency, failure paths, permissions.
   - **Success criteria:** how will we know it works? What gets tested, and how?
   - **Existing art:** is there a utility/pattern already in the codebase to reuse?
3. **Stop when answers stop changing the design** — usually 1–2 rounds. Do not
   interrogate past the point of diminishing returns.
4. **Restate the spec** in ≤10 bullet points and get a confirmation before writing
   code. This restatement is the contract; hand it to the executor verbatim.

## Anti-patterns

- Asking questions answerable by reading the code — read instead.
- One question at a time across many turns — batch them.
- Skipping the restatement — the interview is worthless if the conclusion isn't
  pinned down in writing.
