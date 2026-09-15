# AI

One-click coding agents with Juspay's LLM configuration.

Supports **[OpenCode](https://opencode.ai/)** and **[Oh My Pi (OMP)](https://github.com/can1357/oh-my-pi)**. Skills are built from these sources into an OMP plugin at build time (see [Skills](#skills)):

- [juspay/skills](https://github.com/juspay/skills) — Shared AI agent skills
- [anthropics/skills](https://github.com/anthropics/skills) — `frontend-design` skill
- [juspay/kolu](https://github.com/juspay/kolu/tree/master/agents/.apm/skills/kolu) — `kolu` terminal automation skill

<figure>
<img alt="OpenCode demo: variant selector, oneclick, and hello world prompt" src="demo/demo.gif" />
<figcaption>OpenCode running in the terminal with Juspay's LLM (<code>just demo</code> to regenerate)</figcaption>
</figure>

## Prerequisites

- **Nix** — Install via [the Nix installer](https://nixos.asia/en/install). New to Nix? See the [Nix First Steps](https://nixos.asia/en/nix-first) tutorial.
- **Gateway API key** *(Juspay employees only)* — Create one at [grid.ai.juspay.net/dashboard](https://grid.ai.juspay.net/dashboard) (requires VPN to create, but **not** to use afterwards). The `*-juspay-*` variants read it as `JUSPAY_API_KEY`, except `omp-juspay-oneclick`, which reads `LITELLM_API_KEY` — the name OMP's own LiteLLM support uses. Each wrapper prompts for its own name if it is unset. Not needed for non-Juspay variants.

## Quick Start

```bash
nix run github:juspay/AI
```

This launches an interactive selector. Or run a specific variant directly:

**OpenCode**

| Variant | Command | Description |
|---|---|---|
| `opencode-juspay-oneclick` | `nix run github:juspay/AI#opencode-juspay-oneclick` | Juspay config and skills bundled |
| `opencode-oneclick` | `nix run github:juspay/AI#opencode-oneclick` | Skills bundled, bring your own provider (e.g. Claude Max) |
| `opencode-juspay-editable` | `nix run github:juspay/AI#opencode-juspay-editable` | Creates editable Juspay config at `~/.config/opencode/opencode.json` ([customize](https://opencode.ai/docs/config/)) |
| `opencode` | `nix run github:juspay/AI#opencode` | Plain OpenCode, no config |

**Oh My Pi**

| Variant | Command | Description |
|---|---|---|
| `omp-juspay-oneclick` | `nix run github:juspay/AI#omp-juspay-oneclick` | Juspay gateway and skills bundled |
| `omp` | `nix run github:juspay/AI#omp` | Plain Oh My Pi, no config |

The `*-juspay-*` variants need a gateway API key. Each wrapper prompts for it interactively if it isn't set — handy on fresh VMs or containers. Export the variable in your shell to skip the prompt on subsequent runs.

### Daily Updates

This flake's `flake.lock` is **auto-updated daily** via CI, so you always get the latest OpenCode release and skills. If pinning via `flake.lock` in your own flake, run `nix flake update AI` to pull the latest. The gateway model snapshot is not part of that — refresh it with `just refresh-gateway-models` when the gateway changes.

## Home Manager module (config only)

If you manage your environment with [Home Manager](https://nix-community.github.io/home-manager/) and already have an `opencode` binary — from `nixpkgs`, or bundled with another tool — you can install **just the Juspay config**, without a wrapper or a second opencode, via the exposed module:

```nix
# flake inputs
juspay-ai.url = "github:juspay/AI";

# home configuration
{
  imports = [ inputs.juspay-ai.homeModules.opencode ];
  programs.opencode-juspay.enable = true;
}
```

This renders the same `opencode.json` as the packaged variants and writes it to `$XDG_CONFIG_HOME/opencode/opencode.json`. As with the `opencode-juspay-*` variants, the Juspay provider needs `JUSPAY_API_KEY` in the environment at runtime.

| Option | Default | Description |
|---|---|---|
| `programs.opencode-juspay.enable` | `false` | Install the config (no binary). |
| `programs.opencode-juspay.juspay` | `true` | Include the Juspay litellm provider/model settings. Set `false` for the base settings only. |
| `programs.opencode-juspay.settings` | `{}` | Extra opencode settings merged on top. |

The module is system-agnostic — it uses your config's `pkgs`, so it does not pull in this flake's `nixpkgs`.

## Tips

### Web UI

OpenCode can run as a web application in your browser:

```bash
nix run github:juspay/AI#opencode -- web
```

This starts a local server and opens OpenCode in your default browser. Sessions are shared between the web UI and CLI, so you can switch between them seamlessly. You can also specify a port or make it accessible on your network with `--port 4096 --hostname 127.0.0.1`.

See the [OpenCode Web docs](https://opencode.ai/docs/web/) for more.

### GLM reasoning-effort tiers

`glm-latest` (GLM-5.2) reasons by default. To trade thinking depth for speed, the
model picker (`ctrl+x m`) exposes the same model at several reasoning-effort tiers —
GLM-5.2 collapses low/medium into "high", so these are the only distinct levels:

| Picker entry | `reasoning_effort` | Use it for |
|---|---|---|
| `glm-latest` | *(gateway default)* | the default — thinking on |
| `glm-max`    | `max`  | deepest reasoning |
| `glm-high`   | `high` | strong reasoning, faster |
| `glm-fast`   | `none` | no thinking, fastest replies |

<figure>
<img alt="Switching GLM reasoning-effort tiers from the OpenCode model picker" src="demo/glm-effort-picker.gif" />
<figcaption>Picking a GLM reasoning-effort tier in OpenCode (<code>ctrl+x m</code>)</figcaption>
</figure>

The tiers are defined in [`coding-agents/opencode/settings/juspay.nix`](coding-agents/opencode/settings/juspay.nix);
all target the same gateway model (`glm-latest`) and differ only in `reasoningEffort`.

### Oh My Pi and the LiteLLM gateway

OMP ships LiteLLM discovery, so `omp-juspay-oneclick` vendors no model list at
all. The wrapper points OMP at the gateway, hands it the key under the name OMP
expects, and OMP asks the gateway what it serves — ids, context windows,
capabilities — at startup:

```bash
nix run github:juspay/AI#omp-juspay-oneclick -- --model litellm/kimi-k3
```

The variant also uses a temporary `PI_CODING_AGENT_DIR` and loads the skills
plugin through its `config.yml` `extensions:` key. What the picker shows is what your key can
actually call, with the limits the gateway enforces. If you run OMP yourself
rather than through the wrapper, those same two variables are all it needs:

```bash
export LITELLM_BASE_URL=https://grid.ai.juspay.net
export LITELLM_API_KEY=...   # the gateway key
omp
```

### Gateway model catalog

opencode cannot discover a private OpenAI-compatible endpoint — its provider
catalog is models.dev plus models declared in config — so it reads a snapshot of
the gateway, generated from the gateway itself:

```bash
JUSPAY_API_KEY=... just refresh-gateway-models
```

That rewrites [`coding-agents/gateway-models.nix`](coding-agents/gateway-models.nix)
(ids, context windows, capabilities, fewer hand-kept numbers to drift), prints
the diff, and is a no-op when nothing changed. It needs a key the gateway lets
read one of LiteLLM's model-info routes, and refuses to write a snapshot that
would otherwise lose every capability flag. Availability is per key, so the
snapshot reflects the key used to refresh it — `git log` on that file is its
clock. The `opencode-juspay-editable` variant seeds its config once and then
leaves it alone, so that copy is yours: delete it to pick up a newer snapshot.

## Skills

The skills listed at the top are **not vendored into this repo**.
[`coding-agents/omp/plugin.nix`](coding-agents/omp/plugin.nix) composes them in
the Nix store into a single Oh My Pi **plugin package**:

```
/nix/store/...-omp-juspay-skills-plugin/
├── package.json          # the `omp` manifest: { "omp": { "skills": "./skills" } }
└── skills/
    ├── nix-haskell/SKILL.md      # …and the rest of juspay/skills
    ├── frontend-design/SKILL.md  # anthropics/skills
    └── kolu/SKILL.md             # juspay/kolu
```

The manifest is the point: OMP's loader skips any package that lacks one, and
with it the package can be named under `extensions:` in `config.yml` — which is
exactly what `omp-juspay-oneclick` does. OMP's `omp-plugins` skill provider then
discovers `skills/<name>/SKILL.md` next to it.

opencode has no plugin notion, so the `opencode-*-oneclick` variants are handed
the package's `skills/` subdirectory directly. One build, two consumers.

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

## Development

```bash
just test                       # run the wrapper package tests (NixOS VMs, Linux only)
just refresh-gateway-models     # refresh the gateway model snapshot (needs the key)
just demo                       # re-record the demo screencast
```

## Repo Structure

```
├── coding-agents/
│   ├── catalog.nix           # Gateway policy (URL, key name, recommendation)
│   ├── gateway-models.nix    # GENERATED: what the gateway serves (for opencode)
│   ├── refresh-gateway-models.py  # Regenerates the snapshot from the gateway
│   ├── wrapper.nix           # Shared wrapper shell: key prompt, temp config dir
│   ├── selector.nix          # `nix run` variant chooser (see flake.nix's frontDoor)
│   ├── opencode/             # OpenCode packages, settings, home-module
│   ├── omp/                  # Oh My Pi packages, incl. plugin.nix (the skill bundle)
│   └── test/standalone/      # Wrapper package tests (NixOS VM flake)
├── demo/                     # Demo screencast infrastructure
```

The skill sources are fetched and built into an OMP plugin package in the store
— see [Skills](#skills). Nothing is committed to this repo.

## Related

- [juspay/skills](https://github.com/juspay/skills) — Shared AI agent skills; also an OMP / Claude Code plugin marketplace
- [OpenCode Documentation](https://opencode.ai/docs/) — Full docs on usage, configuration, and providers
- [OpenCode GitHub](https://github.com/anomalyco/opencode) — The upstream OpenCode project
- [llm-agents.nix](https://github.com/numtide/llm-agents.nix) — The upstream Nix packaging that this flake builds on
