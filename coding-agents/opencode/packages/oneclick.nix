{ pkgs, lib, opencode, configFile, skillsSrc }:
let
  ocLib = import ./lib.nix;
  configDir = ocLib.mkConfigDir { inherit pkgs configFile skillsSrc; };
in
pkgs.writeShellApplication {
  name = "opencode";
  text = ''
    export OPENCODE_CONFIG_DIR=${configDir}
    exec ${lib.getExe opencode} "$@"
  '';
}
