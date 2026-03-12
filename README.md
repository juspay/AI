# OpenCode Nix

> **Status: Work In Progress** - This project is under active development.

A Nix flake for running OpenCode with company-specific LiteLLM configuration.

## Quick Start (Milestone 1 - Planned)

```bash
nix run github:juspay/oc
```

## Project Overview

This project provides a `nix run` way to quickly spin up [OpenCode](https://opencode.ai) using company-specific LiteLLM configuration. The implementation references [srid/nixos-config PR #103](https://github.com/srid/nixos-config/pull/103) (home-manager module).

## Milestones

### Milestone 1: Basic `nix run` Launch

**Goal:** `nix run` launches opencode using [numtide/llm-agents.nix](https://github.com/numtide/llm-agents.nix).

**Tasks:**

1. **Create `flake.nix` with llm-agents.nix input**
   - Add `llm-agents.nix` as flake input
   - Configure binary cache (required for pre-built packages):
     ```nix
     nixConfig = {
       extra-substituters = [ "https://numtide.cachix.org" ];
       extra-trusted-public-keys = [ "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE=" ];
     };
     ```
   - Export opencode package as default app

2. **GitHub Workflow for Daily Flake Updates**
   - Create `.github/workflows/update-flake.yml`
   - Use `DeterminateSystems/update-flake-lock` action
   - Configure auto-merge when CI passes
   - **Edge Cases:**
     - Concurrent updates: Use rebase strategy to avoid conflicts
     - CI failures: Do NOT auto-merge; create PR for manual review
     - Token permissions: Need `contents: write` and `pull-requests: write`
     - Branch protection: Auto-merge requires bypass or admin token
   - **Workflow Schedule:** Daily at midnight UTC (`cron: '0 0 * * *'`)

3. **Platform Support**
   - Supported: `x86_64-linux`, `aarch64-linux`, `aarch64-darwin`
   - Runtime dependencies (wrapped by llm-agents.nix): `fzf`, `ripgrep`

**Verification:**
```bash
nix run . -- --help
```

---

### Milestone 2: Company Configuration

**Goal:** Add Juspay-specific LiteLLM configuration from [PR #103](https://github.com/srid/nixos-config/pull/103).

**Tasks:**

1. **Create home-manager module for opencode**
   - The `programs.opencode` module is provided by [home-manager upstream](https://github.com/nix-community/home-manager/blob/master/modules/programs/opencode.nix)
   - Available options:
     - `programs.opencode.settings` - JSON config for opencode.json
     - `programs.opencode.commands` - Custom slash commands
     - `programs.opencode.agents` - Custom agent definitions
     - Custom agent definitions
     - `Custom agent definitions
     - `programs = location gettingettings`
     - `programs opencode
      - Listrollup
żroll
     - `Addition
- `agents` grams` commands

     - `programs.opencode.skills` - Custom skills
     - `programs.opencode.themes` - Custom themes
     - `programs.opencode.tools` - Custom tools

2. **Define Juspay Provider Configuration**
   - Create `modules/juspay.nix` with provider settings:
     ```nix
     {
       npm = "@ai-sdk/openai-compatible";
       name = "Juspay";
       options = {
         baseURL = "https://grid.ai.juspay.net";
         apiKey = "{env:JUSPAY_API_KEY}";  # Environment variable
         timeout = 600000;
       };
       models = { ... };  # Import from models.nix
     }
     ```
   - **Edge Case:** The reference implementation uses `{file:...}` syntax with agenix secrets. For `nix run` standalone, use `{env:JUSPAY_API_KEY}` and require user to set the environment variable.

3. **Define Available Models**
   - Create `modules/models.nix` with model definitions:
     - `open-large`, `open-fast`, `open-vision`
     - `claude-opus-4-5`, `claude-opus-4-6`, `claude-sonnet-4-5`, `claude-sonnet-4-6`
     - `glm-latest`, `glm-flash-experimental`
     - `gemini-3-pro-preview`, `gemini-3-flash-preview`
     - `minimax-m2`, `kimi-latest`
   - Each model needs: `name`, `modalities`, `limit.context`, `limit.output`

4. **Configure Default Settings**
   - Default model: `litellm/glm-latest`
   - Explore agent with `litellm/open-fast` for fast codebase search
   - MCP: Enable deepwiki remote server
   - **Edge Case:** The `agent.explore` configuration uses subagent mode for parallel search tasks.

5. **Secret Handling**
   - **Option A (Recommended for `nix run`):** Environment variable
     - User sets: `export JUSPAY_API_KEY="..."`
     - Config uses: `apiKey = "{env:JUSPAY_API_KEY}"`
   - **Option B (For home-manager integration):** Agenix secrets
     - Use `{file:/run/user/1000/agenix/juspay-anthropic-api-key}`
     - Requires agenix setup in host config

6. **Create Wrapper Script**
   - Wrap opencode with environment setup
   - Check for `JUSPAY_API_KEY` and warn if not set
   - **Edge Case:** Some users may have multiple API keys; consider supporting `OPENCODE_API_KEY` as fallback.

**Verification:**
```bash
export JUSPAY_API_KEY="your-key"
nix run . -- --help
# Verify config is generated at ~/.config/opencode/opencode.json
```

---

## Architecture

```
oc/
├── flake.nix              # Main flake with inputs and outputs
├── flake.lock             # Locked dependencies
├── modules/
│   ├── default.nix        # Default opencode configuration
│   ├── juspay.nix         # Juspay provider + models
│   └── models.nix         # Model definitions
├── .github/
│   └── workflows/
│       └── update-flake.yml  # Daily flake updates
└── README.md
```

## Dependencies

- **Runtime:** `opencode` (from llm-agents.nix), `fzf`, `ripgrep`

## Configuration Reference

The opencode configuration is written to `~/.config/opencode/opencode.json`. Key settings:

| Setting | Description | Default |
|---------|-------------|---------|
| `model` | Default model to use | `litellm/glm-latest` |
| `autoupdate` | Auto-update opencode | `true` |
| `provider.litellm` | Juspay LiteLLM provider | See modules/juspay.nix |
| `mcp.deepwiki` | DeepWiki MCP server | enabled |
| `agent.explore` | Fast explore subagent | `litellm/open-fast` |

## Related

- [OpenCode Documentation](https://opencode.ai/docs/)
- [home-manager opencode module](https://github.com/nix-community/home-manager/blob/master/modules/programs/opencode.nix)
- [llm-agents.nix](https://github.com/numtide/llm-agents.nix)
- [Reference Implementation PR #103](https://github.com/srid/nixos-config/pull/103)
