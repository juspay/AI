# AI

One-click **[Oh My Pi (OMP)](https://github.com/can1357/oh-my-pi)** on Juspay's
LLM gateway, with skills bundled. Skills are built at build time from these
sources into an OMP plugin (see [Skills](#skills)):

- [juspay/skills](https://github.com/juspay/skills) — Shared AI agent skills
- [anthropics/skills](https://github.com/anthropics/skills) — `frontend-design` skill
- [juspay/kolu](https://github.com/juspay/kolu/tree/master/agents/.apm/skills/kolu) — `kolu` terminal automation skill

<figure>
<img alt="Oh My Pi answering a prompt through Juspay's LLM gateway" src="demo/demo.gif" />
<figcaption>omp on the Juspay gateway (<code>just demo</code> to regenerate)</figcaption>
</figure>

## Prerequisites

- **Nix** — Install via [the Nix installer](https://nixos.asia/en/install). New to Nix? See the [Nix First Steps](https://nixos.asia/en/nix-first) tutorial.
- **Gateway API key** *(Juspay employees only)* — Create one at [grid.ai.juspay.net/dashboard](https://grid.ai.juspay.net/dashboard) (requires VPN to create, but **not** to use afterwards). Export it as `LITELLM_API_KEY`, the name OMP's own LiteLLM support reads. The wrapper prompts for it if it is unset.

## Quick Start

```bash
nix run github:juspay/AI
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
3. **Writes a throwaway agent directory** (`PI_CODING_AGENT_DIR`) holding a
   generated `config.yml`. That config names the store-built skills plugin under
   `extensions:` and sets the `default` / `smol` model roles (`glm-latest` and
   `open-fast`) so omp does not start on whatever model it finds first.

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

The skills listed at the top are **not vendored into this repo**.
[`coding-agents/omp/plugin.nix`](coding-agents/omp/plugin.nix) composes them in
the Nix store into one directory that Oh My Pi loads as an **extension**:

```
/nix/store/...-omp-juspay-skills-plugin/
└── skills/
    ├── nix-haskell/SKILL.md      # …and the rest of juspay/skills
    ├── frontend-design/SKILL.md  # anthropics/skills
    └── kolu/SKILL.md             # juspay/kolu
```

The layout is the whole contract. The wrapper names that directory under
`extensions:` in its generated `config.yml`, and OMP's `omp-plugins` skill
provider scans `skills/<name>/SKILL.md` beside it — one level deep,
non-recursively, with `skills` hardcoded in OMP.

`nix flake update` picks up new skills; there is nothing to re-vendor — with
one exception. juspay/skills and anthropics/skills are flake inputs, so they
follow the lock. **kolu is pinned by hand** inside `plugin.nix`: its `SKILL.md`
lives under a path kolu marks `export-ignore`, which every Nix flake fetcher
honours, so no flake input can see it. Bumping it means editing the `rev` and
`hash` there.

To get the same skills in your own agent without this flake, install them from
the marketplace instead — see
[juspay/skills](https://github.com/juspay/skills#usage):

```
/marketplace add juspay/skills          # Oh My Pi
/plugin marketplace add juspay/skills   # Claude Code
```

## Daily Updates

This flake's `flake.lock` is **auto-updated daily** via CI, so you always get the
latest omp release and skills. omp is pinned to an upstream **release tag** rather
than a branch, so the daily job resolves the latest release first and rewrites that
ref — `nix flake update` alone can never move a tag-pinned input — and it only ever
moves the pin *forward*, since a release trails the tag it belongs to. If pinning
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

The skill sources are fetched and built into an OMP plugin package in the store
— see [Skills](#skills). Nothing is committed to this repo.

## Related

- [juspay/skills](https://github.com/juspay/skills) — Shared AI agent skills; also an OMP / Claude Code plugin marketplace
- [Oh My Pi](https://github.com/can1357/oh-my-pi) — The upstream agent; its own flake builds the `omp` this repo wraps
