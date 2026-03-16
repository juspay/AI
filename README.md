# OpenCode for Juspay

Pre-configured [OpenCode](https://opencode.ai/docs/) with Juspay's internal LLM API and [Nix skills](https://github.com/juspay/skills) (nix-flake, nix-haskell).

> [!IMPORTANT]
> For **Juspay employees only**.

<img width="1320" height="1098" alt="image" src="https://github.com/user-attachments/assets/8a79ff2d-24c6-4142-a012-46687ab8bdeb" />

## Quick Start

> [!NOTE]
> `JUSPAY_API_KEY` is required. Create one at https://grid.ai.juspay.net/dashboard (requires VPN).

### One-click (recommended)

Everything bundled — config, models, and [skills](https://opencode.ai/docs/skills/). Nothing written to your home directory:

```bash
export JUSPAY_API_KEY=your-api-key
nix run github:juspay/oc#oneclick
```

### Standalone

Same config, but copies it to `~/.config/opencode/opencode.json` on first run so you can edit it:

```bash
export JUSPAY_API_KEY=your-api-key
nix run github:juspay/oc
```

### home-manager

Add the flake input and import the module. `with-skills` includes [juspay/skills](https://github.com/juspay/skills); use `default` if you don't want them.

```nix
{
  inputs.oc.url = "github:juspay/oc";

  outputs = { inputs, ... }: {
    homeConfigurations.yourhost = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        inputs.oc.homeModules.with-skills  # or .default (no skills)
      ];
    };
  };
}
```

Update to latest (flake.lock is auto-updated daily):

```bash
nix flake update oc
```

## Tips

### Web UI

```bash
nix run github:juspay/oc -- web
```

Starts a local server and opens OpenCode in your browser. Sessions are shared between web and CLI. Add `--port 4096 --hostname 0.0.0.0` to expose on your network.

See [OpenCode Web docs](https://opencode.ai/docs/web/).

## Related

- [OpenCode Documentation](https://opencode.ai/docs/)
- [juspay/skills](https://github.com/juspay/skills) — Nix skills for OpenCode
- [llm-agents.nix](https://github.com/numtide/llm-agents.nix)
