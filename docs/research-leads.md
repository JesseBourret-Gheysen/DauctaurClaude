# Research leads — TooDizzle Tech/AI backlog, triaged 2026-07-12

The 21 Tech/AI items from the TooDizzle backlog, researched as seed leads for this
repo's skills/MCP/agents modules. Verdicts are evidence-based (primary sources
fetched July 2026). "Landed in" says where the finding lives in this repo; leads
marked done in TooDizzle are the ones this triage fully resolved.

## Acted on (marked done in TooDizzle)

| Lead | What it turned out to be | Verdict | Landed in |
|---|---|---|---|
| "Anthropic internal best-practices CLAUDE.md" (IG @techwith.ram) | Recycled Anthropic best-practices advice: short CLAUDE.md, plan-first, subagents | Real advice, hyped framing | Already core to `docs/tiered-config-plan.md` §3.3/§6; skill-vs-CLAUDE.md table in `docs/skills-guide.md` |
| Boris Cherny's Claude Code workflow (IG @appinventiv4ai) | Plan before execution, subagents for parallel work, continuous verification | Legit, matches official guidance | Encoded in `config/skills/tiered-delegation` + `grill-first` |
| Matt Pocock skills repo (IG @slashdevhq) | `github.com/mattpocock/skills`, MIT, ~167k stars — real and excellent | Legit, high-leverage | `/grill-me` + `/handoff` ideas re-implemented as `config/skills/grill-first` + `handoff`; repo linked in `docs/skills-guide.md` |
| "Claude skills for designers" (IG @kail.designs) | Mix of one official skill (`canvas-design` in anthropics/skills) + third-party marketplace skills presented as official | Partially hype | `anthropics/skills` referenced in `docs/skills-guide.md`; marketplace lists not adopted |
| "6 Claude skills… UX Designer, Canvas Design, App Store Screenshot" (IG) | Same conflation — "UX Designer"/"App Store Screenshot" are community/marketplace, not Anthropic | Partially hype | Same as above |
| obsidian-mind — "gives Claude big mem" | `github.com/breferrari/obsidian-mind`, MIT — Obsidian vault + 5 hooks + 18 commands + 9 subagents | Real but heavyweight; a MEMORY.md-index pattern covers the core idea far cheaper | Not adopted. Borrowable idea (SessionStart status-injection hook) noted for a future hooks module |
| "Codex will review your work when you're done" | Cross-model review is real and OpenAI-official: `openai/codex-plugin-cc` (`/codex:review`), plus hook-based community variants | Legit pattern; doubles review cost — use selectively | Candidate for the future hooks module (Stop/ExitPlanMode hook → Codex CLI); not shipped yet |
| Reddit "memory/ego/status" prompt tricks (IG @acknowledge.ai) | Original post unlocatable; adjacent published research exists but doesn't support this specific framing | Unverified anecdote | Not adopted |
| Microsoft Agent Lightning (IG @theartificialintelligens) | `github.com/microsoft/agent-lightning`, MIT — RL/fine-tuning framework for agent policies | Real, but zero relevance to a Claude Code config repo | Out of scope |
| "Claude feels nerfed" (Reddit via IG @acknowledge.ai) | Anthropic's April 23 postmortem confirmed 3 real bugs (effort high→medium default, reasoning-cache wipe, over-aggressive verbosity prompt), all reverted by Apr 20; deliberate throttling denied, usage limits reset as compensation | Real degradation, false conspiracy | Context only |
| "Fable 5 system prompt leaked, 3,800 lines/183KB" (IG ×2) | A real unofficial extraction (~1,585 lines / ~120KB) circulated; IG figures inflated ~2.4×. "90% of Fable on Opus" = style mimicry only; benchmark delta ≈ 0 | Partially true, capability claim is hype | Informed the corrected README/plan §5 fallback wording |

## Cataloged, left open (off-topic for this repo)

| Lead | Note |
|---|---|
| Microsoft BitNet (100B-param inference on CPU) | Relevant to the local Ollama stack, not this repo — candidate for a home-lab LLM upgrade experiment |
| "Check qwen 3.5" | Same — the TooDizzle→TorrentReq pipeline runs qwen2.5:3b-instruct; a newer small model is worth a bench |
| OpenDataLoader (PDF→markdown, 100 pages/s) | Useful tool lead; nothing to configure in this repo |
| Kimodo (3D skeleton movement prompts) | Off-topic |
| train-llm-from-scratch (single-GPU billion-param training) | Off-topic |
| Google TimesFM (time-series foundation model) | Off-topic |
| Quant Science post (June 20) | Off-topic |
| Blank IG post (no text detected) | Dead lead |
| Higgsfield Games / "Fable 5 builds games + assets" | Product news, nothing actionable |
