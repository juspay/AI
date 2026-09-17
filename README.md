# AI

Run **[Oh My Pi](https://github.com/can1357/oh-my-pi)** or
**[Codex](https://github.com/openai/codex)** with shared
[Juspay skills](https://github.com/juspay/skills) and the
[Kolu skill and MCP server](https://github.com/juspay/kolu).

## Quick start

[Install Nix](https://nixos.asia/en/install), then pick an agent:

```bash
nix run https://github.com/juspay/AI/archive/refs/heads/main.zip
```

Or launch one directly:

```bash
nix run github:juspay/AI#omp
nix run github:juspay/AI#codex
```

- **OMP** uses Juspay's LLM gateway by default. Create a key at
  [grid.ai.juspay.net/dashboard](https://grid.ai.juspay.net/dashboard) and export
  `LITELLM_API_KEY`, or let the launcher prompt. To use your own provider:
  `JUSPAY=0 nix run github:juspay/AI#omp`.
- **Codex** uses normal Codex authentication: run
  `nix run github:juspay/AI#codex -- login` if needed. Juspay/LiteLLM integration
  is disabled, regardless of `JUSPAY`. The launcher installs/updates the bundled
  plugins in your Codex home while preserving unrelated settings and login.

Pass agent arguments after `--`. The default picker requires an interactive
terminal; use `#omp` or `#codex` in scripts. Kolu's MCP server needs `kolu` on
`PATH`. Supported systems: x86_64 Linux, aarch64 Linux, and Apple Silicon macOS.

Codex is packaged by [sadjow/codex-cli-nix](https://github.com/sadjow/codex-cli-nix).
Both agents and plugin sources receive daily, CI-verified updates.

## Documentation

- [OMP gateway setup and configuration](docs/omp.md)
- [Shared skills, Kolu MCP, and Codex plugin installation](docs/plugins.md)
- [Development, daily updates, and architecture](docs/development.md)

<details>
<summary>OMP demo</summary>

![Oh My Pi answering through Juspay's gateway](demo/demo.gif)

Regenerate with `just demo`.

</details>
