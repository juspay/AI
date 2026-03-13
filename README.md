# OpenCode Nix

One-click access to OpenCode for Nix users.

<img width="1320" height="1098" alt="image" src="https://github.com/user-attachments/assets/8a79ff2d-24c6-4142-a012-46687ab8bdeb" />


## Quick Start

```bash
nix run github:juspay/oc
```

## Juspay Configuration

> [!NOTE]
> For Juspay people: `JUSPAY_API_KEY` needs to be set and can be created at https://grid.ai.juspay.net/dashboard (requires VPN).

Run with Juspay-specific LiteLLM configuration:

```bash
# Set your API key
export JUSPAY_API_KEY=your-api-key

# Run with Juspay configuration
nix run github:juspay/oc#juspay
```

### With home-manager

Add to your home-manager configuration:

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

To update opencode to the latest version (the flake.lock is auto-updated daily):

```bash
nix flake update oc
```

## Tips

### Web UI

OpenCode can run as a web application in your browser:

```bash
nix run github:juspay/oc#juspay -- web
```

This starts a local server and opens OpenCode in your default browser. Sessions are shared between the web UI and CLI, so you can switch between them seamlessly. You can also specify a port or make it accessible on your network with `--port 4096 --hostname 0.0.0.0`.

See the [OpenCode Web docs](https://opencode.ai/docs/web/) for more.

## Related

- [OpenCode Documentation](https://opencode.ai/docs/)
- [llm-agents.nix](https://github.com/numtide/llm-agents.nix)
