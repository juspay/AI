{ ai }:
let
  common = import ./common.nix;
  skillEntries = builtins.readDir "${ai.inputs.juspay-skills}/skills";
  bundledSkills = builtins.filter (name: skillEntries.${name} == "directory")
    (builtins.attrNames skillEntries);
in
{
  name = "claude";
  nodes.machine = { pkgs, ... }: {
    imports = [ common.baseNode ];
    environment.systemPackages = [
      ai.packages.${pkgs.stdenv.hostPlatform.system}.claude
      pkgs.python3
      (pkgs.writeShellScriptBin "kolu" ''
        exec ${pkgs.python3}/bin/python ${./kolu-mcp-fixture.py} "$@"
      '')
    ];
  };
  testScript = ''
    import shlex
    ${common.testPreamble}

    version = machine.succeed("su - testuser -c 'claude --version </dev/null'")
    assert "(Claude Code)" in version, version
    machine.fail("test -e /home/testuser/.omp")

    command = "python ${./check-claude.py} " + shlex.quote('${builtins.toJSON bundledSkills}')
    machine.succeed("su - testuser -c " + shlex.quote(command))
    machine.fail("test -e /home/testuser/.claude/settings.json")
  '';
}
