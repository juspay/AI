{ pkgs, lib, omp, modelsFile, skillsDir }:
let
  piLib = import ../pi/lib.nix { inherit pkgs; };
  configFile = (pkgs.formats.yaml { }).generate "omp-config.yml" {
    skills.customDirectories = [ skillsDir ];
  };
in
pkgs.writeShellApplication {
  name = "omp";
  meta.description = "Oh My Pi with Juspay models and bundled skills";
  text = ''
    ${piLib.ensureApiKey}
    PI_CODING_AGENT_DIR=$(${pkgs.coreutils}/bin/mktemp -d -t omp-agent-XXXXXX)
    export PI_CODING_AGENT_DIR
    ln -s ${modelsFile} "$PI_CODING_AGENT_DIR/models.yml"
    cp ${configFile} "$PI_CODING_AGENT_DIR/config.yml"
    chmod u+w "$PI_CODING_AGENT_DIR/config.yml"
    exec ${lib.getExe omp} "$@"
  '';
}
