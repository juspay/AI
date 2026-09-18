# Skills and plugins

The Juspay profile in [`profile.nix`](../profile.nix) loads the same two portable
plugins on OMP, Codex, and Claude Code:

- [juspay/skills](https://github.com/juspay/skills): the input's root
  `plugin.json` and `skills/<name>/SKILL.md` directories.
- [juspay/kolu](https://github.com/juspay/kolu): its `agent-plugin/` directory,
  containing `plugin.json`, `mcp.json`, and `skills/kolu/SKILL.md`.

Both are pinned flake inputs updated daily. Kolu's skill and MCP declaration
travel together; its server runs `kolu mcp` and needs `kolu` on `PATH`.
If it cannot start, the rest of the agent remains usable; the skill also
describes a CLI fallback.

Plugin adaptation belongs to
[agent-distro](https://github.com/juspay/agent-distro#readme). Its adapters
handle OMP extension roots, Codex marketplace installation, and Claude's
session-local plugin directories.

## Codex

```bash
nix run github:juspay/AI#codex -- login
nix run github:juspay/AI#codex -- mcp list
```

The distribution registers the `juspay-ai` marketplace and installs
`juspay-skills@juspay-ai` and `kolu@juspay-ai`. Skills appear as names such as
`juspay-skills:nix-haskell` and `kolu:kolu`. State lives in `~/.codex`, or
`CODEX_HOME` when set. Unrelated configuration, comments, login, sessions,
skills, and MCP servers are preserved.

A new marketplace store path re-registers and reinstalls the bundled plugins,
including enabling them and replacing edits to their installed copies. Between
path changes, disabled or removed plugins stay that way. Installer errors stop
launch; invalid configuration is not overwritten.

Codex uses its own login and model settings. `AI_GATEWAY` has no effect and
`LITELLM_API_KEY` is not required. User-supplied environment and provider
settings are preserved.

## Claude Code

```bash
nix run github:juspay/AI#claude
nix run github:juspay/AI#claude -- plugin list --json
nix run github:juspay/AI#claude -- plugin details kolu
```

Claude loads `juspay-skills@inline` and `kolu@inline` for the session, alongside
extra plugin directories you supply. A new build supplies new plugin contents.
There is no marketplace registration or wrapper-written user configuration.
`~/.claude/settings.json` is preserved and `CLAUDE_CONFIG_DIR` is honored.

Use normal Claude authentication, models, and settings. `AI_GATEWAY` has no
effect. Your environment, project configuration, and CLI arguments continue to
be handled by Claude itself.

## OMP and manual installation

OMP loads both plugins alongside your own extensions. See the
[OMP guide](omp.md) for the Juspay gateway, key setup, and `AI_GATEWAY=0`.

To install Juspay skills without this distribution, see
[juspay/skills](https://github.com/juspay/skills#usage):

```
/marketplace add juspay/skills          # Oh My Pi
/plugin marketplace add juspay/skills   # Claude Code
```
