{ ai }:
let
  common = import ./common.nix;
in
{
  name = "vanilla";
  nodes.machine = { pkgs, ... }: {
    imports = [ common.baseNode ];
    environment.systemPackages = [
      ai.legacyPackages.${pkgs.stdenv.hostPlatform.system}.vanilla.omp
      pkgs.python3
    ];
  };
  testScript = ''
    ${common.testPreamble}
    # No credential or terminal is available. Vanilla must still reach OMP.
    machine.succeed("su - testuser -c 'omp --version </dev/null'")
    machine.fail("test -e /home/testuser/.omp/agent/config.yml")
    machine.succeed("su - testuser -c 'python ${./check-vanilla.py}'")
    machine.fail("test -e /home/testuser/.omp/agent/config.yml")
  '';
}
