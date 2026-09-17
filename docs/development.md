# Development and updates

## Checks

```bash
nix build .#default .#omp .#codex .#claude
python3 .github/scripts/test-update-flake.py
just test    # NixOS VM tests; Linux with KVM
just demo    # OMP screencast; requires LITELLM_API_KEY
```

The tests exercise real agent discovery without model calls. OMP tests cover
gateway defaults and opt-out; Codex and Claude tests cover their plugin discovery
and user state. Claude connects to an isolated Kolu MCP fixture, and the picker
is exercised through a PTY.

## Daily updates

CI installs upstream Nix with `cachix/install-nix-action`. The update job runs
`nix flake update` directly and uses `peter-evans/create-pull-request` to publish
the resulting pins and version report. OMP release selection emits only version
facts; PR formatting consumes those facts after all inputs are locked. Release
policy and report wording live in separate scripts under `.github/scripts/`.

This flake's `flake.lock` is **auto-updated daily** via CI, so you always get the
latest packaged Codex and Claude Code, omp release, skills and kolu plugin. The
job runs a plain `nix flake update`, so every input rides along with no per-input
wiring — except omp, which
is pinned to an upstream **release tag** rather than a branch, so the job
resolves the latest release first and rewrites that ref (`nix flake update`
alone can never move a tag-pinned input) and it only ever moves the pin
*forward*, since a release trails the tag it belongs to. If pinning
via `flake.lock` in your own flake, run `nix flake update AI` to pull the latest.
Codex and Claude Code track their packaging repositories' default branches, so
the ordinary lock update picks up their release binaries. Update PRs report all
three agents' versions, including when a version is unchanged. The shared CI builds the picker and all
agents on Linux and macOS, runs their VM tests on Linux, and gates the
automatic merge on success.
Nothing about the gateway's models is snapshotted here.

## Architecture

```
├── flake.nix                 # Pins, package composition, public package/app outputs
├── coding-agents/
│   ├── gateway.nix          # Gateway URL and recommended model aliases
│   ├── ensure-api-key.nix   # Shared gateway credential prompt
│   ├── plugin.nix           # Portable Agent Plugins skills bundle
│   ├── picker.nix           # Default interactive agent selection
│   ├── codex/               # Codex plugin installation, no gateway initialization
│   ├── claude/              # Claude plugin format and session loading
│   ├── omp/
│   │   ├── default.nix      # One launcher: initialization + plugin loading
│   │   ├── juspay.nix       # Gateway initialization, skipped when JUSPAY=0
│   │   └── fill-config-defaults.py # Preserve user YAML while filling absent keys
│   └── test/standalone/     # Wrapper integration tests (NixOS VM flake)
├── demo/                    # Demo screencast infrastructure
└── docs/                    # Usage, plugin, and development documentation
```

The skill sources are fetched into the store, then loaded by each adapter
— see [Skills and plugins](plugins.md). Sources are not vendored.

### Boundaries for another agent

Portable plugin contents are reusable independently of gateway integration.
Gateway policy and credential acquisition are shared only by Juspay integrations.
Each agent owns its plugin-loading interface; its Juspay initialization maps
the shared gateway credential and model aliases into that agent's provider names,
role mapping, and configuration format. The YAML merger stays under OMP:
another agent need not use YAML or share OMP's settings semantics.

To add an agent, put its adapter under `coding-agents/<agent>/` and compose its
upstream package with supported plugins in `flake.nix`. Keep Juspay initialization
separate, as `omp/juspay.nix` does. The credential helper provides
`LITELLM_API_KEY`; the integration translates it and the gateway URL to whatever
its client expects. Provider policy and runtime opt-out stay out of portable
plugin loading. The public outputs are `default` (the picker), `omp`, `codex`,
and `claude`.

This follows the [Hickey/Löwy distinction](https://kolu.dev/blog/hickey-lowy/):
separate concepts that are tangled today, and isolate gateway decisions from
upstream agent protocols that change independently. There is no agent registry
or universal wrapper API; the flake is the composition point.
