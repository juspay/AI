# OpenCode Nix

One-click access to OpenCode for Nix users.

<img width="1320" height="1098" alt="image" src="https://github.com/user-attachments/assets/8a79ff2d-24c6-4142-a012-46687ab8bdeb" />


## Quick Start

```bash
nix run --accept-flake-config github:juspay/oc
```

## Juspay Configuration

Run with Juspay-specific LiteLLM configuration:

```bash
# Set your API key
export JUSPAY_API_KEY=your-api-key

# Run with Juspay configuration
nix run --accept-flake-config github:juspay/oc#juspay
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

## Related

- [OpenCode Documentation](https://opencode.ai/docs/)
- [llm-agents.nix](https://github.com/numtide/llm-agents.nix)
