# Profiles and distributions

The framework is [agent-distro](https://github.com/juspay/agent-distro).
`juspay/AI` is a single-profile distribution built with its `lib.mkFlake`.
Adapters, harness packaging pins, pickers, and reusable VM tests live upstream;
this repository supplies Juspay's profile, documentation, and test selection.

## Model

A profile is harness-independent data: a name, description, portable plugins,
and an optional LiteLLM gateway. Plugins use the
[Agent Plugins](https://agent-plugins.org) layout: root `plugin.json`,
`skills/<name>/SKILL.md`, and optional `mcp.json`. Harness adapters translate
that data to each harness's own format. Plugins are the composable unit;
profiles combine their plugin lists with ordinary Nix.

```nix
# profile.nix
{ juspay-skills, kolu }: {
  name = "juspay";
  description = "Juspay skills + Kolu, via Juspay's LiteLLM gateway";
  plugins = [ juspay-skills "${kolu}/agent-plugin" ];
  gateway = {
    url = "https://grid.ai.juspay.net";
    keyEnv = "LITELLM_API_KEY";
    models = { large = "open-large"; small = "open-fast"; };
    keyHint = "Requires Juspay VPN to access the dashboard";
  };
}
```

In-repo profiles:

| Profile | Plugins | Gateway |
|---|---|---|
| `juspay` | juspay/skills, kolu | Juspay LiteLLM |

Vanilla is agent-distro's default: upstream harnesses without plugins or a
gateway. Third parties publish their own distributions; see
[agent-distro's README](https://github.com/juspay/agent-distro#readme).

### Gateway

Only OMP uses the profile's gateway. Its adapter prompts for the key when
needed, sets LiteLLM environment and absent model defaults, and skips provider
onboarding. Without a gateway, OMP uses its own login and provider settings.
`AI_GATEWAY=0` disables gateway initialization at runtime while keeping plugins.
`JUSPAY=0` remains a deprecated alias for one release.

Codex and Claude Code always use their own login. The picker labels them
"uses its own login" when the profile has a gateway. Profile naming and
metadata also supply picker text and the Codex marketplace name, `juspay-ai`.

### Library entry points

These live in agent-distro:

- `lib.mkLaunchers { pkgs; profile; }` returns `omp`, `codex`, `claude`, and `picker`.
- `lib.mkFlake { profile; }` implements a single-profile distribution's outputs.
- `lib.selectSkills plugin [ "nix-build" ... ]` and evaluation-time plugin/skill
  name collision checks are still planned there.

```nix
outputs = { agent-distro, my-skills, ... }:
  agent-distro.lib.mkFlake {
    profile = {
      name = "my-team";
      description = "My team's harnesses";
      plugins = [ my-skills ];
      gateway = null;
    };
  };
```

### Flake outputs

- `packages.<system>.{default,omp,codex,claude}` and matching `apps`.
- `profiles.juspay`: resolved profile data with plugin sources already bound.

The default package is the harness picker, binary `ai`:

```bash
nix run github:juspay/AI
nix run github:juspay/AI#omp
AI_HARNESS=codex nix run github:juspay/AI
```

There is no profile picker, `AI_PROFILE`, or `legacyPackages` output.
`AI_HARNESS` makes harness selection noninteractive. Each direct package
exports its harness binary, and the picker references all three launchers.
CI builds the four flat package outputs and uses devour-flake for cache builds.

### Installing on NixOS

```nix
environment.systemPackages = with ai.packages.${pkgs.system}; [
  omp
  codex
  claude
];
```

For customization, use agent-distro's library and the resolved profile:

```nix
environment.systemPackages = builtins.attrValues (agent-distro.lib.mkLaunchers {
  inherit pkgs;
  profile = ai.profiles.juspay // { gateway = null; };
});
```

OMP prompts for `LITELLM_API_KEY` unless exported or the gateway is disabled.
Kolu's MCP server needs `kolu` on `PATH`. The phase 2 Home Manager module below
is planned in agent-distro.

### Tests

`test/flake.nix` selects all twelve applicable checks from agent-distro's test
library against this distribution's packages and profile. Coverage includes
all three harnesses, gateway defaults and opt-out, the deprecation line,
the picker's own-login label, isolated Kolu MCP fixtures, and second-build
plugin re-registration/re-path tests from #181. `just test` overrides the
committed test lock's AI input with the checkout. Vanilla and generic framework
coverage belong to agent-distro.

## Relation to agent-skills-nix

[Kyure-A/agent-skills-nix](https://github.com/Kyure-A/agent-skills-nix) installs
skills into a user's home. Agent-distro instead launches wrapped harnesses
with plugins, MCP, and an optional gateway; Kolu needs MCP. The framework does
not depend on agent-skills-nix. Skill selection, collision checks, a catalog,
and Home Manager/devShell delivery remain useful planned framework features.
Plugin sources here are `flake = false` inputs updated by daily CI.

## Phasing

Remaining work belongs in agent-distro or a separate distribution:

1. **Ekala and composition.** Add a root Agent Plugins manifest to Ekala's
   skills, publish its own distribution, and implement `lib.selectSkills`
   and plugin/skill name collision checks in agent-distro.
2. **Discovery and delivery.** Explore a catalog of profiles/plugins/skills,
   an opt-in community distribution list, a Home Manager module, and a devShell
   helper in agent-distro. A community list should show source repositories,
   review entries as data, test distributions independently, and expose skill
   changes in update reviews.
