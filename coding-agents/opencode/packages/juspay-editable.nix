{ pkgs, lib, opencode, configFile }:
let
  ocLib = import ./lib.nix;
in
pkgs.runCommand "opencode-juspay-editable" {
  nativeBuildInputs = [ pkgs.makeWrapper ];
  meta.mainProgram = "opencode";
} ''
  mkdir -p $out/bin
  makeWrapper ${lib.getExe opencode} $out/bin/opencode \
    --run 'export OPENCODE_WRAPPER_ARGS="$@"' \
    --run '${ocLib.mkInitScript configFile}'
''
