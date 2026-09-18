{ ai }:
let
  common = import ./common.nix;
  skillEntries = builtins.readDir "${ai.inputs.juspay-skills}/skills";
  bundledSkills = builtins.filter (name: skillEntries.${name} == "directory")
    (builtins.attrNames skillEntries);
in
{
  name = "codex";
  nodes.machine = { pkgs, ... }: {
    imports = [ common.baseNode ];
    environment.systemPackages = [
      ai.legacyPackages.${pkgs.stdenv.hostPlatform.system}.juspay.codex
      (pkgs.writeShellScriptBin "codex-updated" ''
        exec ${pkgs.lib.getExe (common.updatedLaunchers ai pkgs).codex} "$@"
      '')
      pkgs.python3
      (pkgs.writeShellScriptBin "codex-upstream" ''
        exec ${pkgs.lib.getExe ai.inputs.codex-cli.packages.${pkgs.stdenv.hostPlatform.system}.default} "$@"
      '')
    ];
  };
  testScript = ''
    import shlex
    ${common.testPreamble}

    # Fresh default home, no gateway key, and no explicit opt-out.
    version = machine.succeed("su - testuser -c 'codex --version </dev/null'")
    assert "codex-cli" in version, version
    config = machine.succeed("cat /home/testuser/.codex/config.toml")
    assert "litellm" not in config.lower()
    assert "model_provider" not in config
    machine.fail("test -e /home/testuser/.omp")

    command = "python ${./check-codex.py} " + shlex.quote('${builtins.toJSON bundledSkills}')
    machine.succeed("su - testuser -c " + shlex.quote(command))
    assert machine.succeed("cat /home/testuser/.codex/config.toml") == config
  '';
}
