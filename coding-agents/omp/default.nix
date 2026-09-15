# The one thing this flake ships: Oh My Pi, pointed at Juspay's LiteLLM gateway,
# with this repo's skills plugin loaded. `name = "omp"`, so the binary on $PATH
# is the one Oh My Pi's own docs talk about.
#
# Everything Juspay-specific lives here rather than in a catalog module: with a
# single consumer, a separate file was one more indirection between the wrapper
# and the four strings it substitutes.
{ lib, writeShellApplication, formats, gum, coreutils, llm-agents, skillsPlugin }:
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
  defaultModel = "glm-latest";
  smallModel = "open-fast";

  configFile = (formats.yaml { }).generate "omp-config.yml" {
    # OMP's `omp-plugins` skill provider scans `skills/` next to every extension
    # directory named here. That sibling scan is the whole mechanism — there is
    # no manifest to declare, and `skills.customDirectories` is dead in the omp
    # this flake ships. See coding-agents/omp/plugin.nix.
    extensions = [ "${skillsPlugin}" ];
    # Without this OMP starts on its own first-available model; the roles are how
    # our recommendation reaches the agent.
    modelRoles = {
      default = "litellm/${defaultModel}";
      smol = "litellm/${smallModel}";
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

        # Give OMP a writable per-run agent directory holding the generated config
        # and nothing else. It cannot live in the store: OMP writes into it.
        PI_CODING_AGENT_DIR=$(${coreutils}/bin/mktemp -d -t omp-agent-XXXXXX)
        export PI_CODING_AGENT_DIR
        cp ${configFile} "$PI_CODING_AGENT_DIR/config.yml"
        chmod u+w "$PI_CODING_AGENT_DIR/config.yml"

        # These two are how OMP finds the gateway and asks it what it serves, so the
        # model list is the gateway's, not a copy we maintain.
        export LITELLM_BASE_URL=${gatewayUrl}
        exec ${lib.getExe llm-agents.omp} "$@"
  '';
}
