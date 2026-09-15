{ pkgs, lib, opencode, configFile, skillsDir }:
let
  wrapper = import ../../wrapper.nix { inherit pkgs; };
in
pkgs.writeShellApplication {
  name = "opencode";
  text = ''
    ${wrapper.mkTempAgentDir {
      envVar = "OPENCODE_CONFIG_DIR";
      prefix = "opencode-config";
      links = { "opencode.json" = configFile; skills = skillsDir; };
    }}
    exec ${lib.getExe opencode} "$@"
  '';
}
