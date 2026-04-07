{ pkgs, lib, opencode, configFile, skillsDir }:
let
  ocLib = import ./lib.nix;
  configDir = ocLib.mkConfigDir { inherit pkgs configFile skillsDir; };
in
pkgs.writeShellApplication {
  name = "opencode";
  text = ''
    export OPENCODE_CONFIG_DIR=${configDir}
    exec ${lib.getExe opencode} "$@"
  '';
}
