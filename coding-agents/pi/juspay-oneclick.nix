{ pkgs, lib, pi, modelsFile, skillsDir }:
let
  piLib = import ./lib.nix { inherit pkgs; };
in
pkgs.writeShellApplication {
  name = "pi";
  text = ''
    ${piLib.ensureApiKey}
    ${piLib.setupAgentDir { inherit modelsFile; }}
    # --skill is repeatable; our vendored skills are loaded alongside (not
    # instead of) any skills the user passes themselves.
    exec ${lib.getExe pi} --skill ${skillsDir} "$@"
  '';
}
