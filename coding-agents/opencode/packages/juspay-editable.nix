{ pkgs, lib, opencode, configFile }:
let
  wrapper = import ../../wrapper.nix { inherit pkgs; };
in
pkgs.writeShellApplication {
  name = "opencode";
  text = ''
    ${wrapper.ensureApiKey}
    ${wrapper.seedConfigFile {
      src = configFile;
      dir = "$HOME/.config/opencode";
      name = "opencode.json";
    }}
    exec ${lib.getExe opencode} "$@"
  '';
}
