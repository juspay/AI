{ pkgs, lib, omp, skillsPlugin }:
let
  wrapper = import ../wrapper.nix { inherit pkgs; };
  catalog = import ../catalog.nix;
  configFile = (pkgs.formats.yaml { }).generate "omp-config.yml" {
    # The skills reach OMP as a plugin package, not as a bare directory: OMP's
    # `omp-plugins` skill provider scans `skills/` next to every extension
    # package named here, and the package's manifest is what marks it as one.
    # See coding-agents/omp/plugin.nix.
    extensions = [ "${skillsPlugin}" ];
    # Without this OMP starts on its own first-available model; the roles are how
    # the catalog's recommendation reaches this agent.
    modelRoles = {
      default = "litellm/${catalog.defaultModel}";
      smol = "litellm/${catalog.smallModel}";
    };
  };
in
pkgs.writeShellApplication {
  name = "omp";
  text = ''
    # OMP's LiteLLM support reads the key under its own name, LITELLM_API_KEY —
    # not the JUSPAY_API_KEY that opencode's generated config references.
    ${wrapper.ensureApiKey { env = "LITELLM_API_KEY"; }}
    ${wrapper.mkTempAgentDir {
      envVar = "PI_CODING_AGENT_DIR";
      prefix = "omp-agent";
      copies = { "config.yml" = configFile; };
    }}
    # These two are how OMP finds the gateway and asks it what it serves, so the
    # model list here is the gateway's, not a copy we maintain.
    export LITELLM_BASE_URL=${catalog.gatewayUrl}
    exec ${lib.getExe omp} "$@"
  '';
}
