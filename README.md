# AI

The Juspay distribution of **[Oh My Pi](https://github.com/can1357/oh-my-pi)**,
**[Codex](https://github.com/openai/codex)**, and
**[Claude Code](https://code.claude.com/docs)**, with Juspay skills and Kolu.
Built with [agent-distro](https://github.com/juspay/agent-distro); see its
[README](https://github.com/juspay/agent-distro#readme) to build your own distribution.

## Quick start

[Install Nix](https://nixos.asia/en/install), then pick a harness or launch directly:

```bash
nix run github:juspay/AI          # harness picker
nix run github:juspay/AI#omp
nix run github:juspay/AI#codex
nix run github:juspay/AI#claude
```

- **OMP** prompts for `LITELLM_API_KEY` unless exported. Create a key at
  [grid.ai.juspay.net/dashboard](https://grid.ai.juspay.net/dashboard).
  Use `AI_GATEWAY=0 nix run github:juspay/AI#omp` for your own provider while
  keeping the plugins.
- **Codex** uses its own login: `nix run github:juspay/AI#codex -- login`.
  It installs the plugins while preserving unrelated settings and login.
- **Claude Code** uses its own login and loads the plugins for the session.

Pass harness arguments after `--`. For scripts, use a direct launcher or
`AI_HARNESS=omp AI_GATEWAY=0 nix run github:juspay/AI -- --version`.
Without `AI_HARNESS`, the picker requires a terminal.
Kolu's MCP server needs `kolu` on `PATH`.
Supported systems: x86_64 Linux, aarch64 Linux, and Apple Silicon macOS.

Migration: `#juspay.omp` → `#omp`, `#juspay.codex` → `#codex`, `#juspay.claude` → `#claude`.
`#vanilla`, `#kolu`, and `AI_PROFILE` are removed; plain harnesses are `nix run github:juspay/agent-distro`.

`JUSPAY=0` still works for one release with a deprecation message; use `AI_GATEWAY=0`.
Harness pins follow agent-distro. This distribution receives daily, CI-verified
updates to the framework and plugin sources.

## Documentation

- [OMP gateway setup and configuration](docs/omp.md)
- [Shared skills, Kolu MCP, and agent plugin loading](docs/plugins.md)
- [Development, daily updates, and architecture](docs/development.md)

<details>
<summary>OMP demo</summary>

![Oh My Pi answering through Juspay's gateway](demo/demo.gif)

Regenerate with `just demo`.

</details>
