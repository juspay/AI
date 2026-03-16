# OpenCode Nix

One-click [OpenCode](https://opencode.ai/) for Juspay.

> [!IMPORTANT]
> This flake is for **Juspay employees only**. It provides pre-configured OpenCode with Juspay's internal LLM API.

<figure>
<img alt="OpenCode demo: variant selector, oneclick, and hello world prompt" src="doc/demo/demo.gif" />
<figcaption>OpenCode running in the terminal with Juspay's LLM (<code>just demo</code> to regenerate)</figcaption>
</figure>

## Prerequisites

- **Nix** — Install via [nixone](https://juspay.github.io/nixone/), which also sets up [home-manager](https://github.com/juspay/nixos-unified-template) in `~/.config/home-manager`. New to Nix? See the [Nix First Steps](https://nixos.asia/en/nix-first) tutorial.
- **`JUSPAY_API_KEY`** — Create one at [grid.ai.juspay.net/dashboard](https://grid.ai.juspay.net/dashboard) (requires VPN to create, but **not** to use OpenCode afterwards)

## Quick Start

Run the interactive selector which lets you choose a variant (we recommend `oneclick`):

```bash
export JUSPAY_API_KEY=your-api-key
nix run github:juspay/oc
```

Or run a specific variant directly:

| Variant | Command | Description |
|---|---|---|
| `oneclick` | `nix run github:juspay/oc#oneclick` | Ready to go with Juspay config and [skills](https://opencode.ai/docs/skills/) bundled from [juspay/skills](https://github.com/juspay/skills) |
| `init` | `nix run github:juspay/oc#init` | Creates editable Juspay config at `~/.config/opencode/opencode.json` ([customize](https://opencode.ai/docs/config/)) |
| `opencode` | `nix run github:juspay/oc#opencode` | Plain OpenCode, no Juspay config |

The `JUSPAY_API_KEY` environment variable must be set when running the `oneclick` or `init` variants.

### With home-manager

> [!NOTE]
> If you installed Nix via [nixone](https://juspay.github.io/nixone/), home-manager is already configured at `~/.config/home-manager`. Otherwise, see [nixos-unified-template](https://github.com/juspay/nixos-unified-template) for getting started with home-manager.

Basic setup (no skills):

```nix
{
  inputs.oc.url = "github:juspay/oc";
  
  outputs = { inputs, ... }: {
    homeConfigurations.yourhost = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        inputs.oc.homeModules.default
        {
          programs.opencode.package = inputs.oc.packages.x86_64-linux.opencode;
        }
      ];
    };
  };
}
```

With skills from [juspay/skills](https://github.com/juspay/skills):

```nix
modules = [
  inputs.oc.homeModules.with-skills
  {
    programs.opencode.package = inputs.oc.packages.x86_64-linux.opencode;
  }
];
```

The `JUSPAY_API_KEY` environment variable must be set when running OpenCode.

To update opencode to the latest version (the flake.lock is auto-updated daily on this repo):

```bash
nix flake update oc
```

## Tips

### Web UI

OpenCode can run as a web application in your browser:

```bash
nix run github:juspay/oc#opencode -- web
```

This starts a local server and opens OpenCode in your default browser. Sessions are shared between the web UI and CLI, so you can switch between them seamlessly. You can also specify a port or make it accessible on your network with `--port 4096 --hostname 127.0.0.1`.

See the [OpenCode Web docs](https://opencode.ai/docs/web/) for more.

## Related

- [OpenCode Documentation](https://opencode.ai/docs/) — Full docs on usage, configuration, and providers
- [OpenCode GitHub](https://github.com/anomalyco/opencode) — The upstream OpenCode project
- [llm-agents.nix](https://github.com/numtide/llm-agents.nix) — The upstream Nix packaging that this flake builds on
- [juspay/skills](https://github.com/juspay/skills) — Juspay's AI skills
