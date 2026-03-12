# OpenCode Nix

One-click access to OpenCode for Nix users.

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
    homeManagerModules.yourmodule = {
      imports = [ inputs.oc.homeModules.default ];
    };
  };
}
```

## Related

- [OpenCode Documentation](https://opencode.ai/docs/)
- [llm-agents.nix](https://github.com/numtide/llm-agents.nix)
