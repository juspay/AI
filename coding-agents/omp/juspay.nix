# Juspay initialization for OMP, composed into the single launcher.
# JUSPAY=0 skips this integration at runtime, without changing Nix outputs.
{ lib, formats, python3, gateway, ensureApiKey }:
let
  # Defaults are merged only into absent keys, preserving /model and /settings
  # choices. Use a round-trip YAML parser to retain comments and quoted values.
  configPython = python3.withPackages (ps: [ ps.ruamel-yaml ]);
  # Plugins are loaded by the launcher, never stored in config.
  configDefaults = (formats.yaml { }).generate "omp-config.yml" {
    # Without this OMP starts on its own first-available model; the roles are how
    # our recommendation reaches the agent.
    modelRoles = {
      default = "litellm/${gateway.models.large}";
      smol = "litellm/${gateway.models.small}";
      task = "litellm/${gateway.models.large}";
      slow = "litellm/${gateway.models.large}";
    };
    # OMP ships this off, so a subagent's row names the agent and nothing else:
    # which model a worker or reviewer actually resolved to is invisible. Our
    # roles point at gateway aliases (`open-large`), and an agent can carry its
    # own model override, so the badge is the only place that answer surfaces.
    task.showResolvedModelBadge = true;
  };
in
''
  if [ "''${JUSPAY:-1}" != "0" ]; then
        ${ensureApiKey}

        # Fill absent defaults in the persistent config, including
        # installations created before this wrapper. Existing keys always win,
        # so /model and /settings choices survive relaunch. Invalid YAML stops
        # launch without a write. Honour OMP's relocated agent directory and
        # its default otherwise.
        agent_dir="''${PI_CODING_AGENT_DIR:-''${HOME:-}/.omp/agent}"
        if [ -n "''${PI_CODING_AGENT_DIR:-}''${HOME:-}" ]; then
          ${configPython}/bin/python ${./fill-config-defaults.py} "$agent_dir/config.yml" ${configDefaults}
        fi

        # These two are how OMP finds the gateway and asks it what it serves, so the
        # model list is the gateway's, not a copy we maintain.
        export LITELLM_BASE_URL=${lib.escapeShellArg gateway.url}
        # Kept even though the agent dir now persists and the wizard would only
        # run once. Everything it asks — provider, key, model — the wrapper has
        # already answered above, so the one run it would get is a run spent
        # re-entering the key we just prompted for. An explicitly forced setup
        # (`omp setup`) still works.
        export OMP_SKIP_SETUP=1
  fi
''
