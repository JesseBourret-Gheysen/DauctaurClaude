# DauctaurClaude

Central home for Claude / Claude Code configuration and tooling for the instances under my care. The core module is a **tiered model setup** that spends frontier tokens on judgment and cheap tokens on volume — tuned for research + SWE — now joined by a **skills library**, an **MCP guide + template**, and a **subagent library**.

## What the setup does

Configures Claude Code to plan with a strong model and execute with a cheap one:

- **Main model `opusplan`** — Opus reasons during plan mode, auto-switches to Sonnet for execution. Reliable, built-in, does most of the work.
- **`deep-reasoner` subagent (Opus)** — architecture, algorithm design, hard debugging. Returns a distilled conclusion, not its full trace.
- **`fast-worker` subagent (Sonnet)** — boilerplate, tests, formatting, mechanical edits.
- **`scraper-researcher` subagent (Sonnet)** — wide/shallow web gathering; returns a cited fact sheet, keeps page dumps out of your context.
- **Skills** (`tiered-delegation`, `grill-first`, `handoff`) — on-demand procedures that cost ~one description line until invoked. See [`docs/skills-guide.md`](docs/skills-guide.md).
- **MCP** — no servers auto-installed; [`docs/mcp-guide.md`](docs/mcp-guide.md) covers Tool Search token economics, the MCP-vs-CLI rule, and an annotated [`.mcp.json` template](config/mcp/mcp-servers.template.json).
- **`effortLevel: high`** — the model default; escalate deliberately, not by habit.

Reported effect of correct tiering: ~40% up to 5–10x lower spend versus running everything on the top model, with no meaningful quality loss on well-specified work. Full rationale, pricing, and workflow recipes: [`docs/tiered-config-plan.md`](docs/tiered-config-plan.md).

## One-click install

Clone, then run the script for your OS. Both are **non-destructive** — they back up any file they touch with a timestamped `.bak` suffix and merge into existing `settings.json` rather than overwriting it.

**Linux / macOS**
```bash
git clone https://github.com/JesseBourret-Gheysen/DauctaurClaude.git
cd DauctaurClaude
chmod +x setup.sh
./setup.sh                 # install settings + agents to ~/.claude
./setup.sh --with-claude   # also install a global ~/.claude/CLAUDE.md
./setup.sh --dry-run       # preview, change nothing
```

**Windows (PowerShell)**
```powershell
git clone https://github.com/JesseBourret-Gheysen/DauctaurClaude.git
cd DauctaurClaude
powershell -ExecutionPolicy Bypass -File .\setup.ps1
# options: -WithClaude   -DryRun   -ClaudeHome D:\path
```

Installs into `~/.claude` (`%USERPROFILE%\.claude` on Windows). Override with `CLAUDE_HOME=...` (bash) or `-ClaudeHome` (PowerShell).

## Verify after install

1. `claude`
2. `/model` → shows `opusplan`
3. `/agents` → lists `deep-reasoner`, `fast-worker`, `scraper-researcher`; type `/` → the three skills appear
4. Invoke `deep-reasoner` and confirm it runs as **Opus**, not the parent model.

> **Known bug:** on some Claude Code versions the subagent `model:` field is ignored and resolves to the parent model ([#43869](https://github.com/anthropics/claude-code/issues/43869), [#26179](https://github.com/anthropics/claude-code/issues/26179)). If routing is broken on your version, `opusplan` alone still delivers the plan-strong / execute-cheap split reliably.

## Bio-research note

Fable 5 runs safety classifiers on **cybersecurity, biology & chemistry, distillation, and frontier-LLM-development** content. On a flag, Claude Code re-runs that request on Opus 4.8 and **shows a notice in the transcript** — it is *not* silent — but the fallback is sticky: the session stays on Opus until you re-run `/model fable`. Anthropic reports >95% of Fable sessions involve no fallback at all. A biotech repo's context can still trip this early in a session, so if a Fable session "feels different," check `/model` before debugging your config. (This setup defaults to `opusplan`, not Fable, so it's unaffected unless you switch to Fable manually.) Source: [Fable 5 announcement](https://www.anthropic.com/news/claude-fable-5-mythos-5) + Claude Code model-config docs.

## Repo layout

```
DauctaurClaude/
├── README.md
├── setup.sh                     # Linux / macOS installer
├── setup.ps1                    # Windows installer
├── config/
│   ├── settings.json            # model=opusplan, effortLevel=high
│   ├── CLAUDE.md.template       # per-project orchestration memory
│   ├── agents/
│   │   ├── deep-reasoner.md     # Opus, reasoning
│   │   ├── fast-worker.md       # Sonnet, execution
│   │   └── scraper-researcher.md # Sonnet, web gathering
│   ├── skills/
│   │   ├── tiered-delegation/   # the routing rules as an invocable skill
│   │   ├── grill-first/         # interrogate the spec before coding
│   │   └── handoff/             # session-continuity doc, cheap re-briefing
│   └── mcp/
│       └── mcp-servers.template.json  # annotated .mcp.json template (not auto-installed)
└── docs/
    ├── tiered-config-plan.md    # full plan: pricing, patterns, recipes
    ├── skills-guide.md          # skill vs CLAUDE.md vs subagent vs hook; SKILL.md format
    ├── mcp-guide.md             # scopes, Tool Search economics, add-a-server checklist
    └── research-leads.md        # audit trail: researched leads → verdicts → where they landed
```

## Roadmap

Remaining future modules: useful hooks (top candidates: a cross-model review hook — Stop/ExitPlanMode → Codex CLI, per `openai/codex-plugin-cc` — and a SessionStart status-injection hook borrowed from obsidian-mind) and project CLAUDE.md templates per stack. Slash commands were dropped as a separate module — Claude Code merged commands into skills.

## Customize

- Force cheap execution for *all* subagents regardless of frontmatter: add `"env": { "CLAUDE_CODE_SUBAGENT_MODEL": "sonnet" }` to `config/settings.json`. Leave unset (default) to keep per-agent control.
- Add more agents in `config/agents/`; re-run the installer (restart Claude Code to pick them up).
- Only escalate to `xhigh`/`max` effort where you've confirmed it changes the output. `ultrathink` in a single prompt deepens that turn only, without raising session effort.
