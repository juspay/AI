# AI

One-click **[Oh My Pi (OMP)](https://github.com/can1357/oh-my-pi)** on Juspay's
LLM gateway, with skills bundled. Skills are built at build time from these
sources into an OMP plugin (see [Skills](#skills)):

- [juspay/skills](https://github.com/juspay/skills) — Shared AI agent skills
- [anthropics/skills](https://github.com/anthropics/skills) — `frontend-design` skill
- [juspay/kolu](https://github.com/juspay/kolu) — the `kolu` agent plugin: terminal automation skill **and** MCP server

<figure>
<img alt="Oh My Pi answering a prompt through Juspay's LLM gateway" src="demo/demo.gif" />
<figcaption>omp on the Juspay gateway (<code>just demo</code> to regenerate)</figcaption>
</figure>

## Prerequisites

- **Nix** — Install via [the Nix installer](https://nixos.asia/en/install). New to Nix? See the [Nix First Steps](https://nixos.asia/en/nix-first) tutorial.
- **Gateway API key** *(Juspay employees only)* — Create one at [grid.ai.juspay.net/dashboard](https://grid.ai.juspay.net/dashboard) (requires VPN to create, but **not** to use afterwards). Export it as `LITELLM_API_KEY`, the name OMP's own LiteLLM support reads. The wrapper prompts for it if it is unset.

## Quick Start

```bash
nix run https://github.com/juspay/AI/archive/refs/heads/main.zip
```

That is the whole product: one package, `default`, also published as `omp` —
`nix run github:juspay/AI#omp` runs the same derivation.

The first run prompts for the gateway key if `LITELLM_API_KEY` is unset — handy
on fresh VMs or containers. Export it in your shell to skip the prompt on
subsequent runs.

## How the wrapper works

The wrapper is a short shell script
([`coding-agents/omp/default.nix`](coding-agents/omp/default.nix)) around
upstream omp. It:

1. **Ensures the gateway key**, prompting for `LITELLM_API_KEY` if it is unset.
2. **Points omp at the gateway** with `LITELLM_BASE_URL`. OMP ships LiteLLM
   discovery, so this flake vendors **no model list at all**: omp asks the
   gateway what it serves — ids, context windows, capabilities — at startup.
   What the model picker shows is what your key can actually call, with the
   limits the gateway enforces.
3. **Loads two extension roots** on omp's own command line — the store-built
   skills bundle (`-e /nix/store/…-omp-juspay-skills-plugin`) and kolu's own
   agent plugin (`-e /nix/store/…/agent-plugin`). CLI extension roots are added
   to whatever `extensions:` your settings already list, so these and your own
   extensions compose.
4. **Fills missing model roles on every launch.** In `~/.omp/agent/config.yml`,
   absent `default` / `task` / `slow` roles get `litellm/open-large`, and an
   absent `smol` role gets `litellm/open-fast`. This also repairs older configs
   so workers and reviewers have explicit defaults independent of the primary.

That config file is **yours** — the ordinary settings file `/model` and
`/settings` write to. Existing role assignments, unrelated settings, and YAML
comments are preserved. When all roles are present, the file is not rewritten.
Sessions, auth and onboarding state persist across runs. Removing a role makes
it receive the wrapper default on the next launch; edit its value to choose a
custom model. Invalid YAML is reported without modifying the file.

(If you export `PI_CODING_AGENT_DIR`, the wrapper fills roles there instead.)

If you run omp yourself rather than through the wrapper, those same two
variables are all it needs:

```bash
export LITELLM_BASE_URL=https://grid.ai.juspay.net
export LITELLM_API_KEY=...   # the gateway key
omp
```

Everything else is ordinary omp: `--model litellm/kimi-k3` to start elsewhere,
`ctrl+p` to cycle role models, `/switch` to change provider.

The `omp` binary itself is **upstream's own build**: this flake takes it from
[upstream's flake](https://github.com/can1357/oh-my-pi/blob/main/flake.nix) pinned
to a release tag, and adds only the wrapper above and the skills plugin. If you
would rather manage OMP declaratively, upstream also ships `programs.omp` Home
Manager and NixOS modules — this flake does not use them, and the package here is
a wrapper, not a module.

## Skills

Nothing listed at the top is **vendored into this repo**, and the three sources
arrive two different ways.

**The bundle we compose.** juspay/skills and anthropics/skills are plain trees;
[`coding-agents/omp/plugin.nix`](coding-agents/omp/plugin.nix) copies them in
the Nix store into one directory that Oh My Pi loads as an **extension**:

```
/nix/store/...-omp-juspay-skills-plugin/
└── skills/
    ├── nix-haskell/SKILL.md      # …and the rest of juspay/skills
    └── frontend-design/SKILL.md  # anthropics/skills
```

The layout is the whole contract. The wrapper passes that directory to omp as
`-e <dir>`, and OMP scans `skills/<name>/SKILL.md` beside every extension root —
one level deep, non-recursively, with `skills` hardcoded in OMP. It goes on the
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

All three sources are ordinary flake inputs, so `nix flake update` bumps every
one of them and there is nothing to re-vendor or re-pin by hand.

To get the same skills in your own agent without this flake, install them from
the marketplace instead — see
[juspay/skills](https://github.com/juspay/skills#usage):

```
/marketplace add juspay/skills          # Oh My Pi
/plugin marketplace add juspay/skills   # Claude Code
```

## Daily Updates

This flake's `flake.lock` is **auto-updated daily** via CI, so you always get the
latest omp release, skills and kolu plugin. The job runs a plain `nix flake
update`, so every input rides along with no per-input wiring — except omp, which
is pinned to an upstream **release tag** rather than a branch, so the job
resolves the latest release first and rewrites that ref (`nix flake update`
alone can never move a tag-pinned input) and it only ever moves the pin
*forward*, since a release trails the tag it belongs to. If pinning
via `flake.lock` in your own flake, run `nix flake update AI` to pull the latest.
Nothing about the gateway's models is snapshotted here, so there is nothing else to
refresh.

## Development

```bash
just test    # run the wrapper package test (NixOS VM, Linux only)
just demo    # re-record the demo screencast (needs LITELLM_API_KEY)
```

## Repo Structure

```
├── coding-agents/
│   ├── omp/
│   │   ├── default.nix       # The package: gateway policy + wrapper shell
│   │   └── plugin.nix        # The skill bundle, built in the store
│   └── test/standalone/      # Wrapper package test (NixOS VM flake)
├── demo/                     # Demo screencast infrastructure
```

The skill sources are fetched into the store and loaded as OMP extension roots
— see [Skills](#skills). Nothing is committed to this repo.

## Related

- [juspay/skills](https://github.com/juspay/skills) — Shared AI agent skills; also an OMP / Claude Code plugin marketplace
- [juspay/kolu](https://github.com/juspay/kolu) — Terminal automation for coding agents; ships the `kolu` agent plugin this flake loads
- [Oh My Pi](https://github.com/can1357/oh-my-pi) — The upstream agent; its own flake builds the `omp` this repo wraps
- [Agent Plugins](https://agent-plugins.org) — The portable plugin standard kolu's package targets and OMP implements
