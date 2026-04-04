# AI

One-click coding agents with Juspay's LLM configuration.

Currently supports **[OpenCode](https://opencode.ai/)** only. Skills are sourced from [juspay/skills](https://github.com/juspay/skills).

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
| `opencode-juspay-oneclick` | `nix run github:juspay/AI#opencode-juspay-oneclick` | Juspay config and skills bundled |
| `opencode-oneclick` | `nix run github:juspay/AI#opencode-oneclick` | Skills bundled, bring your own provider (e.g. Claude Max) |
| `opencode-juspay-editable` | `nix run github:juspay/AI#opencode-juspay-editable` | Creates editable Juspay config at `~/.config/opencode/opencode.json` ([customize](https://opencode.ai/docs/config/)) |
| `opencode` | `nix run github:juspay/AI#opencode` | Plain OpenCode, no config |

The `JUSPAY_API_KEY` environment variable must be set when running the `opencode-juspay-*` variants.

### Daily Updates

This flake's `flake.lock` is **auto-updated daily** via CI, so you always get the latest OpenCode release and skills. If pinning via `flake.lock` in your own flake, run `nix flake update AI` to pull the latest.

## Tips

### Web UI

OpenCode can run as a web application in your browser:

```bash
nix run github:juspay/AI#opencode -- web
```

This starts a local server and opens OpenCode in your default browser. Sessions are shared between the web UI and CLI, so you can switch between them seamlessly. You can also specify a port or make it accessible on your network with `--port 4096 --hostname 127.0.0.1`.

See the [OpenCode Web docs](https://opencode.ai/docs/web/) for more.

## Repo Structure

```
├── coding-agents/
│   └── opencode/             # OpenCode packages, settings, tests
├── demo/                     # Demo screencast infrastructure
```

Skills live in [juspay/skills](https://github.com/juspay/skills) and are pulled in as a flake input.

## Related

- [juspay/skills](https://github.com/juspay/skills) — Shared AI agent skills (also usable via [APM](https://microsoft.github.io/apm/))
- [OpenCode Documentation](https://opencode.ai/docs/) — Full docs on usage, configuration, and providers
- [OpenCode GitHub](https://github.com/anomalyco/opencode) — The upstream OpenCode project
- [llm-agents.nix](https://github.com/numtide/llm-agents.nix) — The upstream Nix packaging that this flake builds on
