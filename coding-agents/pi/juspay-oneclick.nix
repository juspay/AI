{ pkgs, lib, pi, modelsFile, skillsDir }:
let
  wrapper = import ../wrapper.nix { inherit pkgs; };
in
pkgs.writeShellApplication {
  name = "pi";
  text = ''
    ${wrapper.ensureApiKey}
    ${wrapper.mkTempAgentDir {
      envVar = "PI_CODING_AGENT_DIR";
      prefix = "pi-agent";
      links = { "models.json" = modelsFile; };
    }}
    # --skill is repeatable; our vendored skills are loaded alongside (not
    # instead of) any skills the user passes themselves.
    exec ${lib.getExe pi} --skill ${skillsDir} "$@"
  '';
}
