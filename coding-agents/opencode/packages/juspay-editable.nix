{ pkgs, lib, opencode, configFile }:
let
  ocLib = import ./lib.nix;
in
pkgs.writeShellApplication {
  name = "opencode";
  text = ''
    ${ocLib.mkInitScript configFile}
    exec ${lib.getExe opencode} "$@"
  '';
}
