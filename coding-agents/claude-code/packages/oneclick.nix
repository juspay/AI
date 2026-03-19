{ pkgs, lib, claude-code, skillsSrc }:
let
  ccLib = import ./lib.nix;
in
pkgs.runCommand "claude-code-oneclick" {
  nativeBuildInputs = [ pkgs.makeWrapper ];
  meta.mainProgram = "claude";
} ''
  mkdir -p $out/bin
  makeWrapper ${lib.getExe claude-code} $out/bin/claude \
    --run '${ccLib.mkSkillsInitScript skillsSrc}'
''
