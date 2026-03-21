# AI

Shared AI agent configuration and one-click coding agents.

Currently supports **[OpenCode](https://opencode.ai/)** and **[Claude Code](https://docs.anthropic.com/en/docs/claude-code)**. Other agents are coming soon.

<figure>
<img alt="OpenCode demo: variant selector, oneclick, and hello world prompt" src="demo/demo.gif" />
<figcaption>OpenCode running in the terminal with Juspay's LLM (<code>just demo</code> to regenerate)</figcaption>
</figure>

## Prerequisites

- **Nix** — Install via [the Nix installer](https://nixos.asia/en/install), which also sets up [home-manager](https://github.com/juspay/nixos-unified-template) in `~/.config/home-manager`. New to Nix? See the [Nix First Steps](https://nixos.asia/en/nix-first) tutorial.
- **`JUSPAY_API_KEY`** *(Juspay employees only)* — Create one at [grid.ai.juspay.net/dashboard](https://grid.ai.juspay.net/dashboard) (requires VPN to create, but **not** to use afterwards). Not needed for non-Juspay variants.

## Quick Start

```bash
nix run github:juspay/AI
```

This launches an interactive selector. Or run a specific variant directly:

| Variant | Command | Description |
|---|---|---|
| `opencode-juspay-oneclick` | `nix run github:juspay/AI#opencode-juspay-oneclick` | Juspay config and [`.agents/`](.agents/) bundled |
| `opencode-oneclick` | `nix run github:juspay/AI#opencode-oneclick` | [`.agents/`](.agents/) bundled, bring your own provider (e.g. Claude Max) |
| `opencode-juspay-editable` | `nix run github:juspay/AI#opencode-juspay-editable` | Creates editable Juspay config at `~/.config/opencode/opencode.json` ([customize](https://opencode.ai/docs/config/)) |
| `opencode` | `nix run github:juspay/AI#opencode` | Plain OpenCode, no config |
| `claude-code-juspay-oneclick` | `nix run github:juspay/AI#claude-code-juspay-oneclick` | Juspay provider and [`.agents/`](.agents/) skills bundled |
| `claude-code-oneclick` | `nix run github:juspay/AI#claude-code-oneclick` | [`.agents/`](.agents/) skills bundled, bring your own provider |
| `claude-code` | `nix run github:juspay/AI#claude-code` | Plain Claude Code, no config |

The `JUSPAY_API_KEY` environment variable must be set when running the `*-juspay-*` variants.

### Daily Updates

This flake's `flake.lock` (specifically the [llm-agents.nix](https://github.com/numtide/llm-agents.nix) input) is **auto-updated daily** via CI, so you always get the latest OpenCode and Claude Code releases. If pinning via `flake.lock` in your own flake, run `nix flake update AI` to pull the latest.

### With home-manager

> [!NOTE]
> If you installed Nix via [the Nix installer](https://nixos.asia/en/install), home-manager is already configured at `~/.config/home-manager`. Otherwise, see [nixos-unified-template](https://github.com/juspay/nixos-unified-template) for getting started with home-manager.

With Juspay provider (`JUSPAY_API_KEY` must be set):

```nix
{
  inputs.AI.url = "github:juspay/AI";

  outputs = { inputs, ... }: {
    homeConfigurations.yourhost = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        inputs.AI.homeModules.opencode-juspay
        {
          programs.opencode.package = inputs.AI.packages.x86_64-linux.opencode;
        }
      ];
    };
  };
}
```

Without Juspay (bring your own provider, e.g. Claude Max):

```nix
modules = [
  inputs.AI.homeModules.opencode
  {
    programs.opencode.package = inputs.AI.packages.x86_64-linux.opencode;
  }
];
```

#### Claude Code

With Juspay provider:

```nix
modules = [
  inputs.AI.homeModules.claude-code-juspay
  {
    programs.claude-code.package = inputs.AI.packages.x86_64-linux.claude-code;
  }
];
```

Without Juspay:

```nix
modules = [
  inputs.AI.homeModules.claude-code
  {
    programs.claude-code.package = inputs.AI.packages.x86_64-linux.claude-code;
  }
];
```

To update to the latest version:

```bash
nix flake update AI
```

## Tips

### Web UI

OpenCode can run as a web application in your browser:

```bash
nix run github:juspay/AI#opencode -- web
```

This starts a local server and opens OpenCode in your default browser. Sessions are shared between the web UI and CLI, so you can switch between them seamlessly. You can also specify a port or make it accessible on your network with `--port 4096 --hostname 127.0.0.1`.

See the [OpenCode Web docs](https://opencode.ai/docs/web/) for more.

## Agent Configuration (`.agents/`)

The [`.agents/`](.agents/) directory contains shared AI agent configuration using the [nix-agent-wire](https://github.com/srid/nix-agent-wire) convention. Currently ships [skills](.agents/skills/); commands, MCP servers, and other agent configuration will follow.

This configuration is wired into agents via `autoWire.dirs` (home-manager) or bundled directly (oneclick packages).

## Repo Structure

```
├── .agents/                  # Shared agent configuration (skills, commands, MCP, etc.)
│   └── skills/               # AI skills
├── coding-agents/
│   ├── opencode/             # OpenCode packages, home modules, settings, tests
│   └── claude-code/          # Claude Code packages, home modules, tests
├── demo/                     # Demo screencast infrastructure
```

## Related

- [OpenCode Documentation](https://opencode.ai/docs/) — Full docs on usage, configuration, and providers
- [OpenCode GitHub](https://github.com/anomalyco/opencode) — The upstream OpenCode project
- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code) — Official Claude Code docs
- [llm-agents.nix](https://github.com/numtide/llm-agents.nix) — The upstream Nix packaging that this flake builds on
- [nix-agent-wire](https://github.com/srid/nix-agent-wire) — Wires `.agents/` content into coding agents via Nix
