# Generalizing juspay/AI: profiles

Status: phase 1 implemented; the remaining phases below are planned.

## Goal

Today this repo is useful to Juspay employees: three harnesses (OMP, Codex,
Claude Code) launched with juspay/skills, the Kolu plugin, and, for OMP, Juspay's
LiteLLM gateway. The goal is to make it useful to the general public, and to let
other organisations and communities (Ekala first) ship their own bundle.

"Harness" here means what the repo's code calls a coding agent: `omp`, `codex`,
`claude`. The repo keeps the name `juspay/AI`.

## Principles

- **Profiles are harness-independent.** A profile never names a harness. Every
  profile works on every harness this repo supports (claude, codex, omp). Adding
  a harness is a change to this repo, and all profiles get it.
- **One plugin format.** A plugin is a directory in the harness-neutral
  [Agent Plugins](https://agent-plugins.org) 1.0.0 layout: root `plugin.json`,
  `skills/<name>/SKILL.md`, optional `mcp.json`. Translating that into each
  harness's own layout is the harness adapter's job, as it is today.
- **Plugins are the only composable unit.** There is no separate "role" concept.
- **Framework first.** The core is a Nix library that others use to ship their
  own distribution. This repo also ships ready-made profiles so individuals can
  just `nix run`.
- **Build-time composition, runtime choice.** Profiles are Nix values. The
  default app lets the user pick among the in-repo profiles.

## Model

A profile is plain data: a list of plugins, an optional gateway, and a
description.

```nix
# profiles/juspay.nix
{ sources }: {
  description = "Juspay skills + Kolu, via Juspay's LiteLLM gateway";
  plugins = [
    sources.juspay-skills
    "${sources.kolu}/agent-plugin"
  ];
  gateway = {
    url = "https://grid.ai.juspay.net";
    keyEnv = "LITELLM_API_KEY";
    models = { large = "open-large"; small = "open-fast"; };
    keyHint = "Requires Juspay VPN";
  };
}
```

In-repo profiles:

| Profile | Plugins | Gateway |
|---|---|---|
| `vanilla` | none | none |
| `kolu` | kolu | none |
| `juspay` | juspay/skills, kolu | Juspay LiteLLM |
| `ekala` (planned, phase 1 of Phasing) | ekala skills | none |

`vanilla` is the baseline for public users: the Nix-packaged harnesses with
daily CI-verified updates and nothing else.

### Plugins

A plugin is a path to an Agent Plugins directory. There are no constructors or
format converters.

- juspay/skills ships a root `plugin.json`, so the flake input itself is the
  plugin. `coding-agents/plugin.nix`, which rebuilds that manifest, is deleted.
- Kolu ships its plugin at `agent-plugin/`, passed through as today.
- ekala-claude-skills has harness-neutral `skills/<name>/SKILL.md` directories,
  but its only manifest is `.claude-plugin/plugin.json`. We send Ekala a PR
  adding a root Agent Plugins `plugin.json`, the way juspay/skills ships one
  alongside its Claude and OMP marketplace files. The `ekala` profile lands
  after that PR merges.

### Gateway

`gateway` describes one LiteLLM proxy: `{ url; keyEnv; models; keyHint; }`.
LiteLLM is the only kind of gateway; there is no provider abstraction.

- The gateway applies to OMP only, by design. Codex and Claude Code always use
  their own login, whatever the profile says.
- `gateway.nix`, `juspay.nix` and `ensure-api-key.nix` become the OMP adapter's
  handling of `profile.gateway`: prompt for `keyEnv` if unset, export
  `LITELLM_BASE_URL`, fill absent `modelRoles` with `litellm/<models.*>`, set
  `OMP_SKIP_SETUP=1`. Any organisation with a LiteLLM proxy can use it.
- A profile without `gateway` leaves OMP on its own `/login` and provider
  settings.
- `AI_GATEWAY=0` skips the gateway at runtime without changing Nix outputs. It
  replaces `JUSPAY=0`, which is honoured for one release with a deprecation
  message.
- When a profile has a gateway, the picker labels Codex and Claude Code "uses
  its own login".

### Composition

Profiles compose with plain Nix (`plugins = kolu.plugins ++ [ ... ]`). There is
no `imports` mechanism.

### Library entry points

- `lib.mkLaunchers { pkgs; profile; }` returns `{ omp, codex, claude, picker }`.
- `lib.mkFlake { profile; }` returns a whole flake's outputs for a
  single-profile distribution.
- `lib.selectSkills plugin [ "nix-build" ... ]` returns a plugin holding only the
  named skills, so a profile can combine parts of several sources.

Evaluation fails, naming both paths, when two plugins in a profile share a
plugin name or a skill name.

A third party's flake:

```nix
# github:ekala-project/ai
outputs = { AI, ekala-skills, ... }:
  AI.lib.mkFlake { profile = { plugins = [ ekala-skills ]; }; };
```

### Flake outputs

- `packages.<system>.default`: the profile picker, then the harness picker.
- `packages.<system>.<profile>`: that profile's harness picker.
- `legacyPackages.<system>.<profile>.<harness>`: one harness, launched directly.

```
nix run github:juspay/AI              # pick profile, then harness
nix run github:juspay/AI#juspay       # juspay profile, pick harness
nix run github:juspay/AI#juspay.omp   # no prompts
```

`AI_PROFILE` and `AI_HARNESS` make the pickers non-interactive.

Why the split: `nix flake check` requires every `packages.<system>.*` to be a
derivation, so `packages.<system>.juspay.omp` fails it (verified: `flake
attribute 'packages.x86_64-linux.juspay' is not a derivation`). `legacyPackages`
may nest and is not checked, and `nix run` searches `packages` then
`legacyPackages`, so both forms above resolve. The pickers stay in `packages`
because `nix run .#juspay` needs a derivation at that path: Nix does not fall
back to `juspay.default` inside a nested attrset (verified). `nix flake show`
lists the pickers and omits `legacyPackages`.

CI builds every output with devour-flake, which covers `packages`, `apps`,
`checks` and `devShells` but not `legacyPackages`. Each picker `exec`s its
launchers, so building `packages.<system>.<profile>` builds and caches all of
that profile's launchers; CI needs no per-launcher list.

The flake also exports `profiles.<name>`: each in-repo profile as a resolved
attrset (sources already bound), so consumers can pass it to `lib.mkLaunchers`,
with or without overrides.

### Installing on NixOS

The launchers are ordinary packages. Each `<profile>.<harness>` puts a
`bin/<harness>` on `PATH`, so one profile per harness can be installed at a
time.

```nix
environment.systemPackages = with ai.legacyPackages.${pkgs.system}.juspay; [
  omp
  codex
  claude
];
```

Equivalent, via the lib, which is also how a customised profile is installed:

```nix
environment.systemPackages = builtins.attrValues (ai.lib.mkLaunchers {
  inherit pkgs;
  profile = ai.profiles.juspay;   # or: ai.profiles.juspay // { gateway = null; }
});
```

As with `nix run`, OMP prompts for `LITELLM_API_KEY` unless it is exported, and
Kolu's MCP server needs `kolu` on `PATH`. The phase 4 Home Manager module
reduces this to `programs.ai.profile = "juspay";`.

The harness binaries are shared across profiles; only the plugin directories
differ. The default picker already pulls in all three harnesses today, so
`#default` adds only those directories to the closure.

### Branding

These derive from the profile name and description:

- Codex marketplace name (`juspay-ai` today).
- Picker text.
- API-key prompt wording.

### Tests

The VM tests cover:

- the `juspay` profile on all three harnesses (plugins, MCP, gateway),
- the `vanilla` profile on OMP (no gateway, no plugins),
- both pickers through a PTY.

## Relation to Kyure-A/agent-skills-nix

That project installs skills into the user's home (Home Manager, or a sync
script) for ten targets, with flake-pinned sources, discovery, selection, and
bundling. Its plugin export is skills-only, rejects MCP servers, and emits a
Codex-specific manifest.

This repo launches ephemeral wrapped harnesses with MCP and a gateway, and Kolu
needs MCP. We do not depend on agent-skills-nix. We take these ideas from it:

- skill-level selection (`lib.selectSkills`),
- eval-time collision checks,
- a catalog app,
- Home Manager and devShell delivery of the same profile value.

We do not take its npins source registry. Community profile sources are
`flake = false` inputs, updated by the existing daily `nix flake update` job.

## Community list

Third parties publish from their own flake via the lib. This repo also keeps an
opt-in list of community profiles that its picker offers.

- Entries are data only: sources plus a plugin list, no arbitrary Nix. Review
  means checking which repositories an entry points at.
- CI builds each profile separately. A community profile that fails to build is
  pinned back to its last good revision and does not block `#default`.
- Skills are a prompt-injection surface. The picker shows each profile's
  sources, and the daily update PR shows skill diffs for community entries.

## Phasing

1. **Ekala.**
   - Root `plugin.json` PR to ekala-claude-skills.
   - `profiles/ekala.nix`, after the PR merges.
   - `lib.selectSkills` and collision checks.
2. **Distribution support.**
   - `lib.mkFlake`.
   - A `nix flake init -t github:juspay/AI` template.
   - A "ship your own distribution" doc.
   - Ekala moves to its own repo.
3. **Discovery and delivery.**
   - `nix run .#catalog`: JSON of profiles, plugins and skills, which also feeds
     picker descriptions and a generated README table.
   - Community list.
   - Home Manager module (`programs.ai.profile = ...`).
   - devShell helper, so a project declares its own profile in its flake.
