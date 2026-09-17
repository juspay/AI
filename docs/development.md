# Development and updates

## Checks

```bash
nix build .#default .#vanilla .#kolu .#juspay
nix build .#juspay.omp .#juspay.codex .#juspay.claude .#vanilla.omp
nix flake check
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
├── flake.nix                 # Pins, resolved profiles, public outputs
├── profiles/                 # vanilla.nix, kolu.nix, juspay.nix: plain data
├── lib/mk-launchers.nix      # Profile + package set → all harness launchers
├── coding-agents/
│   ├── profile-picker.nix   # Profile selection (AI_PROFILE)
│   ├── picker.nix           # Harness selection (AI_HARNESS)
│   ├── codex/               # Profile marketplace installation, own login
│   ├── claude/              # Plugin adaptation and session loading, own login
│   ├── omp/
│   │   ├── default.nix      # Plugins and optional LiteLLM gateway
│   │   └── fill-config-defaults.py # Preserve YAML while filling absent keys
│   └── test/standalone/     # NixOS VM integration tests
├── demo/                    # Demo screencast infrastructure
└── docs/                    # Usage, development, and design documentation
```

The skill sources are fetched into the store, then loaded by each adapter
— see [Skills and plugins](plugins.md). Sources are not vendored.

### Boundaries for another agent

Profiles are harness-independent data: `name`, `description`, `plugins`, and
an optional `gateway`. Each adapter owns its plugin-loading protocol. Only OMP
uses the gateway, including credential acquisition and YAML defaults.

To add a harness, put its adapter under `coding-agents/<harness>/`, bind its
upstream package in `lib/mk-launchers.nix`, and add it to the harness picker.
Every profile then gets the harness. Keep profile-specific names and sources
out of adapters, and test plugin discovery and preservation of user state.

`packages.<system>.default` selects a profile and then a harness;
`packages.<system>.<profile>` selects a harness.
`legacyPackages.<system>.<profile>.<harness>` launches directly. Flat package
outputs keep `nix flake check` valid. Profile pickers reference every launcher,
so CI's existing devour-flake build includes their closures.

Consumers can use `profiles.<name>` and
`lib.mkLaunchers { pkgs; profile; }`, which returns `omp`, `codex`, `claude`,
and `picker`. For example, override `gateway = null` in the resolved Juspay
profile to retain its plugins without gateway initialization.

See the [profiles design](design/profiles.md) for the implemented refactor and
future phases.
