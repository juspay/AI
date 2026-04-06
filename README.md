# AI

One-click coding agents with Juspay's LLM configuration.

Supports **[Claude Code](https://code.claude.com/)** and **[OpenCode](https://opencode.ai/)**. Skills are sourced from [juspay/skills](https://github.com/juspay/skills).

<figure>
<img alt="OpenCode demo: variant selector, oneclick, and hello world prompt" src="demo/demo.gif" />
<figcaption>OpenCode running in the terminal with Juspay's LLM (<code>just demo</code> to regenerate)</figcaption>
</figure>

## Prerequisites

- **Nix** — Install via [the Nix installer](https://nixos.asia/en/install). New to Nix? See the [Nix First Steps](https://nixos.asia/en/nix-first) tutorial.
- **`JUSPAY_API_KEY`** *(Juspay employees only)* — Create one at [grid.ai.juspay.net/dashboard](https://grid.ai.juspay.net/dashboard) (requires VPN to create, but **not** to use afterwards). Not needed for non-Juspay variants.

## Quick Start

```bash
nix run github:juspay/AI
```

This launches an interactive selector. Or run a specific variant directly:

| Variant | Command | Description |
|---|---|---|
| `claude-code-juspay-oneclick` | `nix run github:juspay/AI#claude-code-juspay-oneclick` | Claude Code with Juspay config and skills |
| `opencode-juspay-oneclick` | `nix run github:juspay/AI#opencode-juspay-oneclick` | OpenCode with Juspay config and skills |
| `opencode-oneclick` | `nix run github:juspay/AI#opencode-oneclick` | OpenCode with skills, bring your own provider (e.g. Claude Max) |
| `opencode-juspay-editable` | `nix run github:juspay/AI#opencode-juspay-editable` | Creates editable Juspay config at `~/.config/opencode/opencode.json` ([customize](https://opencode.ai/docs/config/)) |
| `opencode` | `nix run github:juspay/AI#opencode` | Plain OpenCode, no config |

The `JUSPAY_API_KEY` environment variable must be set when running the `*-juspay-*` variants.

### Daily Updates

This flake's `flake.lock` is **auto-updated daily** via CI, so you always get the latest releases and skills. If pinning via `flake.lock` in your own flake, run `nix flake update AI` to pull the latest.

## Tips

### Web UI

OpenCode can run as a web application in your browser:

```bash
nix run github:juspay/AI#opencode -- web
```

This starts a local server and opens OpenCode in your default browser. Sessions are shared between the web UI and CLI, so you can switch between them seamlessly. You can also specify a port or make it accessible on your network with `--port 4096 --hostname 127.0.0.1`.

See the [OpenCode Web docs](https://opencode.ai/docs/web/) for more.

## Coding Agent Setup

This repo uses [APM](https://microsoft.github.io/apm/) (via [srid/agency](https://github.com/srid/agency)) for coding agent configuration. To set up your coding agent environment:

```bash
just agent       # deploy APM primitives + launch agent (default: claude)
just agent::apm  # deploy only, don't launch
```

Override the agent with `AI_AGENT`:

```bash
AI_AGENT=opencode just agent
AI_AGENT='claude --dangerously-skip-permissions' just agent
```

Project instructions live in `agent/.apm/instructions/` and deploy to `.claude/rules/` (or equivalent) via `apm install`.

## Repo Structure

```
├── agent/                    # APM local package (project instructions, mod.just)
├── coding-agents/
│   ├── claude-code/           # Claude Code packages
│   └── opencode/              # OpenCode packages, settings, tests
├── demo/                     # Demo screencast infrastructure
```

Skills live in [juspay/skills](https://github.com/juspay/skills) and are pulled in as a flake input.

## Related

- [juspay/skills](https://github.com/juspay/skills) — Shared AI agent skills (also usable via [APM](https://microsoft.github.io/apm/))
- [Claude Code](https://code.claude.com/) — Anthropic's CLI coding agent
- [OpenCode Documentation](https://opencode.ai/docs/) — Full docs on usage, configuration, and providers
- [OpenCode GitHub](https://github.com/anomalyco/opencode) — The upstream OpenCode project
- [llm-agents.nix](https://github.com/numtide/llm-agents.nix) — The upstream Nix packaging that this flake builds on
