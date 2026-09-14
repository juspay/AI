{ pkgs, lib, omp, modelsFile, skillsDir }:
let
  piLib = import ../pi/lib.nix { inherit pkgs; };
in
pkgs.writeShellApplication {
  name = "omp";
  meta.description = "Oh My Pi with Juspay models and bundled skills";
  text = ''
    ${piLib.ensureApiKey}
    PI_CODING_AGENT_DIR=$(${pkgs.coreutils}/bin/mktemp -d -t omp-agent-XXXXXX)
    export PI_CODING_AGENT_DIR
    ln -s ${modelsFile} "$PI_CODING_AGENT_DIR/models.yml"
    exec ${lib.getExe omp} --skill ${skillsDir} "$@"
  '';
}
