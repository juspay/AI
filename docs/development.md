# Development

## Checks

```bash
nix build .#default .#omp .#codex .#claude
nix flake check
AI_HARNESS=omp AI_GATEWAY=0 nix run . -- --version
python3 .github/scripts/test-update-flake.py
just test    # NixOS VM tests; Linux with KVM
just demo    # OMP screencast; requires LITELLM_API_KEY
```

`test/flake.nix` is a separate flake with a committed lock. `just test` runs
`nix flake check -L ./test --override-input ai .`, testing this checkout's
packages and `profiles.juspay` with agent-distro's reusable test library.
Its nixpkgs follows `ai/agent-distro/nixpkgs` so the VMs use the harness package set.
All twelve applicable checks are selected: harness discovery, the PTY picker
and its own-login labels, gateway defaults and environment, `AI_GATEWAY=0`,
the `JUSPAY=0` deprecation, Kolu MCP fixtures, and same-home second-build
plugin tests for Codex marketplace re-registration and Claude/OMP path changes.
Tests use real harnesses without model calls. `test/omp-readiness.patch` is a
local test-library fix to upstream: it waits for ACP initialization/session
responses with a bounded timeout instead of fixed sleeps, preserving all
skill-set and second-build assertions. Applying it during evaluation requires
Nix's default import-from-derivation support.

Update the root lock first, then the test lock:

```bash
nix flake update
nix flake update --flake ./test
just test
```

The test lock pins a published AI revision for standalone use; the override
in `just test` always selects the checkout, including its current dependency pins.

## Daily updates

The daily workflow updates `agent-distro`, `juspay-skills`, and `kolu`, then
updates the test lock. OMP release-tag advancement happens in agent-distro;
this repo follows its harness pins. The report reads OMP's `original.ref`
from agent-distro's transitive lock node, and evaluates `codex.version` and
`claude.version` from the distribution packages. It reports changed and
unchanged versions and includes both lock-update logs.

CI builds all four packages on Linux and macOS, retains the devour-flake cache
build, and runs `just test` on Linux. The update workflow invokes that same CI
and merges its update PR only after verification succeeds.
Gateway models are discovered at runtime, not snapshotted here.

## Architecture

```
├── flake.nix    # Framework/plugin pins and public outputs
├── profile.nix  # Juspay plugin sources, branding, and LiteLLM gateway
├── test/        # Selection of agent-distro VM tests and a separate lock
├── docs/        # Juspay usage, development, and design documentation
├── demo/        # Screencast infrastructure
└── .github/     # CI, daily updates, and version reporting
```

## Boundaries

Adapters and pickers live in [agent-distro](https://github.com/juspay/agent-distro).
This repo owns `profile.nix`, Juspay documentation, and gateway/Kolu test
selection. Framework behavior and new harness support belong upstream.
Plugin sources remain separate repositories; they are not vendored here.

`agent-distro.lib.mkFlake` turns the profile into
`packages.<system>.{default,omp,codex,claude}` and matching apps. The default
package is the harness picker, binary `ai`. `profiles.juspay` exposes resolved
profile data for consumers, including `gateway = null` overrides via
agent-distro's library. See the [profile design](design/profiles.md).
