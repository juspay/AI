# OpenCode Nix

One-click OpenCode for Juspay.

> [!IMPORTANT]
> This flake is for **Juspay employees only**. It provides pre-configured OpenCode with Juspay's internal LLM API.

<img width="1320" height="1098" alt="image" src="https://github.com/user-attachments/assets/8a79ff2d-24c6-4142-a012-46687ab8bdeb" />


## Quick Start

> [!NOTE]
> `JUSPAY_API_KEY` is required and can be created at https://grid.ai.juspay.net/dashboard (requires VPN).

### One-click

Config and skills embedded in package. Skills from [juspay/skills](https://github.com/juspay/skills) (nix-flake, nix-haskell) are bundled automatically:

```bash
export JUSPAY_API_KEY=your-api-key
nix run github:juspay/oc#oneclick
```

### Default

Auto-creates `~/.config/opencode/opencode.json` on first run. Edit this file to customize:

```bash
export JUSPAY_API_KEY=your-api-key
nix run github:juspay/oc
```

### With home-manager

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
          programs.opencode.package = inputs.oc.packages.x86_64-linux.default;
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
    programs.opencode.package = inputs.oc.packages.x86_64-linux.default;
  }
];
```

To update opencode to the latest version (the flake.lock is auto-updated daily):

```bash
nix flake update oc
```

## Tips

### Web UI

OpenCode can run as a web application in your browser:

```bash
nix run github:juspay/oc -- web
```

This starts a local server and opens OpenCode in your default browser. Sessions are shared between the web UI and CLI, so you can switch between them seamlessly. You can also specify a port or make it accessible on your network with `--port 4096 --hostname 0.0.0.0`.

See the [OpenCode Web docs](https://opencode.ai/docs/web/) for more.

## Related

- [OpenCode Documentation](https://opencode.ai/docs/)
- [llm-agents.nix](https://github.com/numtide/llm-agents.nix)
