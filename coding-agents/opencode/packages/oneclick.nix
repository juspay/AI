{ pkgs, lib, opencode, configFile, skillsSrc }:
let
  ocLib = import ../lib.nix;
  configDir = pkgs.runCommand "opencode-config-dir" { } ''
    mkdir -p $out
    ln -s ${configFile} $out/opencode.json
    ln -s ${skillsSrc}/skills $out/skills
  '';
in
pkgs.runCommand "opencode-juspay" {
  nativeBuildInputs = [ pkgs.makeWrapper ];
  meta.mainProgram = "opencode";
} ''
  mkdir -p $out/bin
  makeWrapper ${lib.getExe opencode} $out/bin/opencode \
    --run 'export OPENCODE_WRAPPER_ARGS="$@"' \
    --run '${ocLib.checkApiKey}' \
    --set OPENCODE_CONFIG_DIR ${configDir}
''
