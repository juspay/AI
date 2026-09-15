{ pkgs, lib, omp, modelsFile, skillsDir }:
let
  wrapper = import ../wrapper.nix { inherit pkgs; };
  configFile = (pkgs.formats.yaml { }).generate "omp-config.yml" {
    skills.customDirectories = [ skillsDir ];
  };
in
pkgs.writeShellApplication {
  name = "omp";
  meta.description = "Oh My Pi with Juspay models and bundled skills";
  text = ''
    ${wrapper.ensureApiKey}
    ${wrapper.mkTempAgentDir {
      envVar = "PI_CODING_AGENT_DIR";
      prefix = "omp-agent";
      links = { "models.yml" = modelsFile; };
      copies = { "config.yml" = configFile; };
    }}
    exec ${lib.getExe omp} "$@"
  '';
}
