# Skills and plugins

Both agents load the same two portable sources. Codex installs them through its
native marketplace commands; OMP loads them directly as extension roots.

Neither [juspay/skills](https://github.com/juspay/skills) nor
[juspay/kolu](https://github.com/juspay/kolu) is vendored into this repository.
The two sources have different packaging owners.

**The bundle we compose.** juspay/skills is a plain tree;
[`coding-agents/plugin.nix`](../coding-agents/plugin.nix) copies it in
the Nix store into one directory that Oh My Pi loads as an **extension**:
```
/nix/store/...-juspay-skills-plugin/
├── plugin.json                 # Agent Plugins 1.0.0 manifest
└── skills/
    └── nix-haskell/SKILL.md     # …and the rest of juspay/skills
```

The bundle uses the portable Agent Plugins format, not an OMP-specific package.
The OMP adapter passes it as `-e <dir>`; OMP discovers the manifest and scans
`skills/<name>/SKILL.md` one level deep, non-recursively. It goes on the
command line rather than into `config.yml` because OMP replaces arrays wholesale
between config layers: an `extensions:` list written by the wrapper would be
dropped the moment you added your own.

**kolu's own package.** juspay/kolu ships an
[Agent Plugins](https://agent-plugins.org) 1.0.0 package at `agent-plugin/` —
`plugin.json`, `mcp.json`, `skills/kolu/SKILL.md` — and the wrapper hands omp
that directory as a *second* `-e` root rather than copying anything out of it.
OMP's `agent-plugins` provider then loads the package as kolu publishes it:

```
github:juspay/kolu → agent-plugin/
├── plugin.json           # "kolu", Agent Plugins 1.0.0
├── mcp.json              # stdio MCP server `kolu`, running `kolu mcp`
└── skills/kolu/SKILL.md
```

That is the point of passing it through: the skill's primary path *is* the MCP
server's tools, so shipping the `SKILL.md` alone (which is what this flake used
to do) would ship the instructions without the tools. The MCP server needs the
`kolu` binary on `PATH` at runtime; if it is missing the server simply fails to
start, and if it is present but no kolu daemon is reachable it exits cleanly —
either way the rest of the agent is unaffected, and the skill documents a CLI
fallback.

Both sources are ordinary flake inputs, so `nix flake update` bumps every
one of them and there is nothing to re-vendor or re-pin by hand.

To get the same skills in your own agent without this flake, install them from
the marketplace instead — see
[juspay/skills](https://github.com/juspay/skills#usage):

```
/marketplace add juspay/skills          # Oh My Pi
/plugin marketplace add juspay/skills   # Claude Code
```

## Codex installation

[`coding-agents/codex/default.nix`](../coding-agents/codex/default.nix) builds a
local `juspay-ai` marketplace in the Nix store, deriving names from the portable
manifests. On each launch, it runs upstream Codex's native commands:

1. `codex plugin marketplace add <store-marketplace>`
2. `codex plugin add juspay-skills@juspay-ai`
3. `codex plugin add kolu@juspay-ai`
4. `codex` with your original arguments.

These commands register the marketplace and install/enable the two plugins in
`~/.codex`, or `CODEX_HOME` when set. They preserve unrelated configuration,
comments, login, sessions, skills, and MCP servers. The wrapper owns these two
bundled installations and reinstalls them on each launch, including `--version`:
flake updates can change plugin contents without changing a manifest version.
Edits to those installed copies are therefore replaced on the next launch.
Native installer errors stop launch; invalid configuration is not repaired or
overwritten by the wrapper.

Codex exposes skill names such as `juspay-skills:nix-haskell` and `kolu:kolu`.
The Kolu MCP server comes from the same upstream `mcp.json` used by OMP; there is
no duplicate server definition here. Check it with:

```bash
nix run github:juspay/AI#codex -- mcp list
```

Codex always uses its normal login and model settings. No Juspay initializer is
composed into it, so `JUSPAY` has no effect and `LITELLM_API_KEY` is not required.
As with OMP's opt-out, the wrapper does not erase environment variables or
provider settings you supplied yourself.

See the official [plugin packaging guide](https://developers.openai.com/plugins/build/plugins)
for portable manifests and native marketplace installation.
