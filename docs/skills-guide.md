# Skills — when and how (token-efficiency lens)

Facts verified against `code.claude.com/docs/en/skills` (July 2026).

## Why skills are the token-efficient home for know-how

Skills use **progressive disclosure** — three loading stages:

1. **Always in context:** only the frontmatter `description` (+ `when_to_use`),
   capped at 1,536 characters combined, for every installed skill.
2. **On invocation:** the full `SKILL.md` body loads only when you type `/name` or
   Claude decides the skill applies.
3. **On demand:** supporting files (`reference.md`, `scripts/`, templates) load only
   when the skill body references them and they're needed.

Compare `CLAUDE.md`, which is injected into **every session, every turn** — a
recurring tax. Rule of thumb:

| Put it in… | When |
|---|---|
| `CLAUDE.md` | Facts needed *every* session: build/test commands, invariants, conventions. Keep it short. |
| A **skill** | Procedures needed *sometimes*: workflows, checklists, domain methods. Pay for the body only when used. |
| A **subagent** | Work whose *intermediate output* would pollute your context: research dumps, bulk edits, deep reasoning traces. |
| A **hook** | Behavior that must happen *deterministically* (format on save, gate on stop) — the harness executes it, no model tokens at all. |

One exception to remember: skills preloaded into a subagent (via its `skills`
frontmatter) inject their **full** content at subagent startup — progressive
disclosure doesn't apply there.

## SKILL.md format

Directory per skill: `~/.claude/skills/<name>/SKILL.md` (personal) or
`.claude/skills/<name>/SKILL.md` (project). Precedence: enterprise > personal >
project > bundled. Legacy `.claude/commands/*.md` files still work — commands and
skills have been merged; a skill directory additionally supports supporting files
and the frontmatter below.

```markdown
---
name: my-skill                  # optional; defaults to directory name
description: What it does and when to use it. This is the ONLY part always
  in context — write it as a trigger, and spend the 1,536-char budget well.
---
The body. Loaded only on invocation. Keep it focused; push detail
into supporting files that load on demand.
```

Useful optional frontmatter (see official docs for the full list):
`when_to_use` (extra trigger phrases, shares the 1,536-char cap),
`disable-model-invocation: true` (user-only, hides from Claude's auto-invocation),
`user-invocable: false` (model-only, hides from the `/` menu),
`allowed-tools` / `disallowed-tools`, `model`, `effort` (turn-scoped overrides),
`context: fork` + `agent` (run the skill inside a subagent), `paths` (glob-scoped
activation), `hooks`.

## Authoring rules that keep skills cheap

1. **The description is the product.** It's the only always-loaded part — make it
   answer "when should this fire?" precisely, so it triggers when relevant and
   never otherwise.
2. **Short body, deep references.** Put the procedure in SKILL.md; move tables,
   examples, and specs into supporting files.
3. **Model-invoked vs user-invoked is a real decision.** Skills that should only
   run when *you* ask (e.g. destructive workflows) get
   `disable-model-invocation: true`.
4. **Steal from the ecosystem before writing your own:**
   - `github.com/anthropics/skills` — official; `skill-creator` (meta-skill for
     authoring skills) and `mcp-builder` are the standouts. Apache 2.0 (except the
     document skills, which are source-available).
   - `github.com/mattpocock/skills` — MIT; `/grill-me`, `/diagnosing-bugs`,
     `/handoff` are the high-leverage ones for solo research + SWE work.

## Skills shipped in this repo (`config/skills/`)

| Skill | What it does |
|---|---|
| `tiered-delegation` | The routing brain of this repo as an invocable procedure: which tier gets which work, delegation rules, effort discipline. |
| `grill-first` | Interview the requester until the spec is unambiguous before any code is written (re-implementation of the `/grill-me` idea). |
| `handoff` | Write a ≤60-line HANDOFF.md so the next session resumes without re-reading the conversation (re-implementation of the `/handoff` idea). |

Installed to `~/.claude/skills/` by `setup.sh` / `setup.ps1`. New skills are picked
up on session restart.
