# OpenCode Nix

> **Status: Work In Progress**

One-click access to OpenCode for Nix users.

## Quick Start

```bash
nix run --accept-flake-config github:juspay/oc
```

## Milestones

### Milestone 1: Basic `nix run` Launch ✓

- Create `flake.nix` using [llm-agents.nix](https://github.com/numtide/llm-agents.nix)
- Add GitHub workflow for daily flake updates with auto-merge
- Platforms: `x86_64-linux`, `aarch64-linux`, `aarch64-darwin`

### Milestone 2: Company Configuration ✓

Add Juspay-specific LiteLLM configuration:

- Create home-manager module using upstream `programs.opencode`
- Define Juspay provider with `apiKey = "{env:JUSPAY_API_KEY}"`
- Add model definitions (glm-latest, claude variants, gemini, etc.)
- Create wrapper script to check for API key

#### Usage

**Quick start with `nix run`:**

```bash
# Set your API key
export JUSPAY_API_KEY=your-api-key

# Run with Juspay configuration
nix run --accept-flake-config github:juspay/oc#juspay
```

**With home-manager:**

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
- [Reference Implementation](https://github.com/srid/nixos-config/pull/103)
