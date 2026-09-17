# AI

Run **[Oh My Pi](https://github.com/can1357/oh-my-pi)**,
**[Codex](https://github.com/openai/codex)**, or
**[Claude Code](https://code.claude.com/docs)** with a choice of profiles.

## Quick start

[Install Nix](https://nixos.asia/en/install), then pick a profile and harness:

```bash
nix run github:juspay/AI
nix run github:juspay/AI#juspay       # pick a harness in this profile
nix run github:juspay/AI#juspay.omp   # launch directly
```

| Profile | Plugins | OMP gateway |
|---|---|---|
| `vanilla` | None | Your own provider |
| `kolu` | Kolu skill and MCP server | Your own provider |
| `juspay` | Juspay skills and Kolu | Juspay LiteLLM |

Every profile supports `omp`, `codex`, and `claude`: for example,
`nix run github:juspay/AI#vanilla.claude`.

- **OMP with the Juspay profile** prompts for `LITELLM_API_KEY` unless exported.
  Create a key at [grid.ai.juspay.net/dashboard](https://grid.ai.juspay.net/dashboard).
  Use `AI_GATEWAY=0 nix run github:juspay/AI#juspay.omp` for your own provider
  while keeping the plugins.
- **Codex** uses its own login: `nix run github:juspay/AI#juspay.codex -- login`.
  It installs the profile's plugins while preserving unrelated settings and login.
- **Claude Code** uses its own login and loads the profile's plugins for the session.

Pass harness arguments after `--`. For scripts, use a direct launcher or
`AI_PROFILE=vanilla AI_HARNESS=omp nix run github:juspay/AI -- --version`.
Without those environment variables, the pickers require a terminal.
Kolu's MCP server needs `kolu` on `PATH`.
Supported systems: x86_64 Linux, aarch64 Linux, and Apple Silicon macOS.

The old `#omp`, `#codex`, and `#claude` outputs have been removed; use
`#juspay.omp`, `#juspay.codex`, and `#juspay.claude`. `JUSPAY=0` is deprecated
and still works for one release; replace it with `AI_GATEWAY=0`.

Codex and Claude Code use [sadjow/codex-cli-nix](https://github.com/sadjow/codex-cli-nix)
and [sadjow/claude-code-nix](https://github.com/sadjow/claude-code-nix).
All agents and plugin sources receive daily, CI-verified updates.

## Documentation

- [OMP gateway setup and configuration](docs/omp.md)
- [Shared skills, Kolu MCP, and agent plugin loading](docs/plugins.md)
- [Development, daily updates, and architecture](docs/development.md)

<details>
<summary>OMP demo</summary>

![Oh My Pi answering through Juspay's gateway](demo/demo.gif)

Regenerate with `just demo`.

</details>
