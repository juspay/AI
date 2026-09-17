# The one thing this flake ships: Oh My Pi, pointed at Juspay's LiteLLM gateway,
# with this repo's skills plugin loaded. `name = "omp"`, so the binary on $PATH
# is the one Oh My Pi's own docs talk about.
#
# Everything Juspay-specific lives here rather than in a catalog module: with a
# single consumer, a separate file was one more indirection between the wrapper
# and the four strings it substitutes.
#
# The wrapper deliberately does *not* isolate OMP from the user's own state. It
# leaves `~/.omp/agent` where OMP puts it, so config, sessions, auth and
# onboarding persist across runs and the config is the user's file to edit. What
# the wrapper contributes is layered on top instead of replacing it: skills come
# in on the command line (`-e`), and absent model roles are filled in
# config.yml on each launch. Existing role assignments remain the user’s choices.
{ lib, writeShellApplication, formats, gum, python3, omp, skillsPlugin, koluPlugin }:
let
  # Juspay gateway policy. There is deliberately no model catalog: OMP ships
  # LiteLLM discovery and asks the gateway at startup what it serves — ids,
  # context windows, capabilities — so a vendored list could only go stale.
  gatewayUrl = "https://grid.ai.juspay.net";
  # Where the prompt below sends users to create a key.
  apiKeyUrl = "${gatewayUrl}/dashboard";
  # The models the agent starts on: role assignments, not a catalog. Each must
  # be an id the gateway actually serves — nothing here validates them, and OMP
  # falls back to its own first-available model if one goes missing.
  defaultModel = "open-large";
  largeModel = "open-large";
  smallModel = "open-fast";

  # Defaults are merged only into absent keys, preserving /model and /settings
  # choices. Use a round-trip YAML parser to retain comments and quoted values.
  configPython = python3.withPackages (ps: [ ps.ruamel-yaml ]);
  #
  # In particular `extensions:` is NOT here. OMP replaces arrays wholesale when
  # a higher config layer sets them, so a user adding their own extension to
  # this file would silently drop the skills plugin; and seeding it once would
  # freeze a store path that changes on every lock bump. The plugin goes on the
  # command line instead (see `-e` below), which composes with whatever
  # `extensions:` the user ends up writing.
  roleDefaults = (formats.yaml { }).generate "omp-config.yml" {
    # Without this OMP starts on its own first-available model; the roles are how
    # our recommendation reaches the agent.
    modelRoles = {
      default = "litellm/${defaultModel}";
      smol = "litellm/${smallModel}";
      task = "litellm/${largeModel}";
      slow = "litellm/${largeModel}";
    };
  };
in
writeShellApplication {
  name = "omp";
  text = ''
        # Ensure the gateway key is set, prompting interactively if it is missing —
        # handy on a fresh VM or container. Always runs: we don't bypass based on
        # args, so the user's positional parameters reach OMP untouched. The `:-`
        # keeps it compatible with nounset (set -u).
        if [ -z "''${LITELLM_API_KEY:-}" ]; then
          cat >&2 <<'MSG'

      LITELLM_API_KEY is not set.

      Create an API key at: ${apiKeyUrl}
      (Requires Juspay VPN to access the dashboard)

      Tip: export LITELLM_API_KEY=... to skip this prompt next time.

    MSG
          if [ ! -t 0 ]; then
            echo "Error: cannot prompt for LITELLM_API_KEY (stdin is not a terminal)." >&2
            exit 1
          fi
          LITELLM_API_KEY=$(${gum}/bin/gum input --password --prompt "LITELLM_API_KEY: ") || {
            echo "Error: failed to read LITELLM_API_KEY." >&2
            exit 1
          }
          if [ -z "$LITELLM_API_KEY" ]; then
            echo "Error: no API key provided." >&2
            exit 1
          fi
          export LITELLM_API_KEY
        fi

        # Fill absent roles in the persistent config, including installations
        # created before this wrapper. Existing keys always win, so /model
        # choices survive relaunch. Invalid YAML stops launch without a write.
        # Honour OMP's relocated agent directory and its default otherwise.
        agent_dir="''${PI_CODING_AGENT_DIR:-''${HOME:-}/.omp/agent}"
        if [ -n "''${PI_CODING_AGENT_DIR:-}''${HOME:-}" ]; then
          ${configPython}/bin/python ${./fill-model-roles.py} "$agent_dir/config.yml" ${roleDefaults}
        fi

        # These two are how OMP finds the gateway and asks it what it serves, so the
        # model list is the gateway's, not a copy we maintain.
        export LITELLM_BASE_URL=${gatewayUrl}
        # Kept even though the agent dir now persists and the wizard would only
        # run once. Everything it asks — provider, key, model — the wrapper has
        # already answered above, so the one run it would get is a run spent
        # re-entering the key we just prompted for. An explicitly forced setup
        # (`omp setup`) still works.
        export OMP_SKIP_SETUP=1

        # Extensions, on the command line rather than in the config file. CLI
        # `-e` roots are merged with the settings `extensions:` list and
        # de-duplicated by absolute path, so these add to the user's extensions
        # instead of replacing them — which a generated `extensions:` would do,
        # since OMP replaces arrays wholesale between config layers. `-e` may be
        # repeated, and there are two roots because they are two different kinds
        # of thing:
        #
        #   1. The bundle this flake composes (coding-agents/omp/plugin.nix): a
        #      bare `skills/` directory, no manifest. OMP's plugin providers
        #      scan `skills/<name>/SKILL.md` beside every extension root, so it
        #      loads on layout alone.
        #
        #   2. kolu's own `agent-plugin/`, an Agent Plugins 1.0.0 package taken
        #      verbatim from juspay/kolu. It is passed through rather than
        #      harvested into (1) so that omp's standard `agent-plugins`
        #      provider reads kolu's `plugin.json` and loads *everything* kolu
        #      declares — the `kolu` skill and the `kolu` MCP server in its
        #      `mcp.json`, which the skill needs to be useful. Copying a
        #      SKILL.md out of it, as this wrapper used to, would ship the
        #      instructions without the tools. The MCP server runs `kolu mcp`,
        #      so it needs `kolu` on PATH at runtime; when it is absent the
        #      server simply fails to start and the rest of the agent is
        #      unaffected.
        exec ${lib.getExe omp} -e "${skillsPlugin}" -e "${koluPlugin}" "$@"
  '';
}
