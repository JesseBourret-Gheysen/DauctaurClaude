# MCP — configuration and token economics

Facts verified against `code.claude.com/docs/en/mcp` and
`anthropic.com/engineering/code-execution-with-mcp` (July 2026).

## The token question first

An MCP server's tool schemas historically loaded into context up front — the reason
"just add more servers" used to be an anti-pattern. That's largely solved:

- **MCP Tool Search is on by default.** At session start only tool *names* + server
  instructions load; full schemas are deferred and fetched on demand via a
  ToolSearch call. Adding servers now has minimal context impact.
- Control it with `ENABLE_TOOL_SEARCH`: unset/`true` = deferred; `auto[:N]` = load
  upfront only if schemas fit within N% (default 10%) of context; `false` = load
  everything upfront (the old behavior).
- Exemptions: per-server `"alwaysLoad": true` (or per-tool
  `_meta["anthropic/alwaysLoad"]`) keeps critical tools loaded upfront.
- **Caveat:** Tool Search needs a model that supports `tool_reference` blocks —
  Haiku models don't. A Haiku subagent with MCP servers loads schemas upfront.
- Tool descriptions/server instructions are truncated at 2 KB each. Single tool
  outputs over 10,000 tokens trigger a warning — raise with `MAX_MCP_OUTPUT_TOKENS`
  if a server legitimately returns more.

**MCP vs CLI rule of thumb:** if a capable CLI exists (`gh`, `docker`, `curl`
against a local API), Claude can drive it through Bash with zero schema overhead
and no extra moving parts — prefer it. Reach for MCP when you need OAuth'd remote
services, resources/prompts, or tools a CLI doesn't expose. For many-tool
workflows, Anthropic's own engineering guidance is to expose MCP servers as code
APIs called from a sandbox rather than direct tool calls — their worked example
cut ~150k tokens to ~2k (98.7%).

## Configuration

Three scopes:

| Scope | Where it lives | Use for |
|---|---|---|
| `local` (default) | `~/.claude.json`, per-project entry | Private, this project only |
| `project` | `.mcp.json` in repo root (checked in) | Shared with the team/repo |
| `user` | `~/.claude.json` | Private, all projects |

Precedence when names collide: local > project > user.

```bash
claude mcp add --transport http <name> <url>       # remote (recommended); OAuth supported
claude mcp add --transport stdio <name> -- <cmd>   # local process
claude mcp add-json <name> '<json>'                # raw JSON
claude mcp list / get / remove                     # manage
```

Transports: `stdio` (local process), `http` (recommended remote), `sse`
(deprecated — use http), `ws` (JSON-config only).

`.mcp.json` shape — see [`config/mcp/mcp-servers.template.json`](../config/mcp/mcp-servers.template.json)
for an annotated template. Env expansion (`${VAR}`, `${VAR:-default}`) works in
`command`, `args`, `env`, `url`, `headers`. Per-server `"timeout"` (ms) overrides
`MCP_TOOL_TIMEOUT`.

## Checklist before adding a server

1. **Is there a CLI that already does this?** If yes, stop — Bash + CLI is free.
2. **Which scope?** Secrets or personal accounts → `local`/`user`, never a
   checked-in `.mcp.json`. Use `${VAR}` expansion instead of literal keys.
3. **Will it be used most sessions?** Rarely-used servers belong in a project scope
   where they're relevant, not globally in every session.
4. **Does it return huge payloads?** Plan for `MAX_MCP_OUTPUT_TOKENS`, and prefer
   servers with filter/limit parameters.
5. **After adding:** `claude mcp list`, then check `/context` — with Tool Search on,
   the footprint should be near-zero until tools are actually used.

## This repo's stance

No servers are auto-installed. `config/mcp/mcp-servers.template.json` documents the
shape with placeholder examples — copy what you need into a project `.mcp.json` or
`claude mcp add` it. On this home-lab, most services (TooDizzle, TorrentReq,
Prowlarr, Ollama, qBittorrent) already speak plain HTTP on the local network, which
Claude drives through `curl` with zero schema overhead — that's the CLI rule above
in action.
