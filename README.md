# DauctaurClaude

Central home for Claude / Claude Code configuration and tooling for the instances under my care. The first module is a **tiered model setup** that spends frontier tokens on judgment and cheap tokens on volume — tuned for research + SWE.

## What the setup does

Configures Claude Code to plan with a strong model and execute with a cheap one:

- **Main model `opusplan`** — Opus reasons during plan mode, auto-switches to Sonnet for execution. Reliable, built-in, does most of the work.
- **`deep-reasoner` subagent (Opus)** — architecture, algorithm design, hard debugging. Returns a distilled conclusion, not its full trace.
- **`fast-worker` subagent (Sonnet)** — boilerplate, tests, formatting, mechanical edits.
- **`effortLevel: high`** — the model default; escalate deliberately, not by habit.

Reported effect of correct tiering: ~40% up to 5–10x lower spend versus running everything on the top model, with no meaningful quality loss on well-specified work. Full rationale, pricing, and workflow recipes: [`docs/tiered-config-plan.md`](docs/tiered-config-plan.md).

## One-click install

Clone, then run the script for your OS. Both are **non-destructive** — they back up any file they touch with a timestamped `.bak` suffix and merge into existing `settings.json` rather than overwriting it.

**Linux / macOS**
```bash
git clone https://github.com/<you>/DauctaurClaude.git
cd DauctaurClaude
chmod +x setup.sh
./setup.sh                 # install settings + agents to ~/.claude
./setup.sh --with-claude   # also install a global ~/.claude/CLAUDE.md
./setup.sh --dry-run       # preview, change nothing
```

**Windows (PowerShell)**
```powershell
git clone https://github.com/<you>/DauctaurClaude.git
cd DauctaurClaude
powershell -ExecutionPolicy Bypass -File .\setup.ps1
# options: -WithClaude   -DryRun   -ClaudeHome D:\path
```

Installs into `~/.claude` (`%USERPROFILE%\.claude` on Windows). Override with `CLAUDE_HOME=...` (bash) or `-ClaudeHome` (PowerShell).

## Verify after install

1. `claude`
2. `/model` → shows `opusplan`
3. `/agents` → lists `deep-reasoner`, `fast-worker`
4. Invoke `deep-reasoner` and confirm it runs as **Opus**, not the parent model.

> **Known bug:** on some Claude Code versions the subagent `model:` field is ignored and resolves to the parent model ([#43869](https://github.com/anthropics/claude-code/issues/43869), [#26179](https://github.com/anthropics/claude-code/issues/26179)). If routing is broken on your version, `opusplan` alone still delivers the plan-strong / execute-cheap split reliably.

## Bio-research note

Fable 5 runs safety classifiers on **biology and cybersecurity** content and silently falls back to Opus 4.8 on a flag, staying there until you re-run `/model fable`. A biotech repo's context can trip this on the first message. If a Fable session "feels different," check `/model` before debugging your config. (This setup defaults to `opusplan`, not Fable, so it's unaffected unless you switch to Fable manually.)

## Repo layout

```
DauctaurClaude/
├── README.md
├── setup.sh                     # Linux / macOS installer
├── setup.ps1                    # Windows installer
├── config/
│   ├── settings.json            # model=opusplan, effortLevel=high
│   ├── CLAUDE.md.template       # per-project orchestration memory
│   └── agents/
│       ├── deep-reasoner.md     # Opus, reasoning
│       └── fast-worker.md       # Sonnet, execution
└── docs/
    └── tiered-config-plan.md    # full plan: pricing, patterns, recipes
```

## Roadmap

Future modules for this repo: shared subagent library, project CLAUDE.md templates per stack, useful hooks, MCP connector bundles, and reusable slash commands.

## Customize

- Force cheap execution for *all* subagents regardless of frontmatter: add `"env": { "CLAUDE_CODE_SUBAGENT_MODEL": "sonnet" }` to `config/settings.json`. Leave unset (default) to keep per-agent control.
- Add more agents in `config/agents/`; re-run the installer (restart Claude Code to pick them up).
- Only escalate to `xhigh`/`max` effort where you've confirmed it changes the output. `ultrathink` in a single prompt deepens that turn only, without raising session effort.
