{ ai }:
let
  common = import ./common.nix;
in
{
  name = "picker";
  nodes.machine = { pkgs, ... }: {
    imports = [ common.baseNode ];
    environment.systemPackages = [ ai.packages.${pkgs.stdenv.hostPlatform.system}.default pkgs.python3 ];
  };
  testScript = ''
    ${common.testPreamble}

    status, output = machine.execute("su - testuser -c 'ai --version </dev/null 2>&1'")
    assert status != 0
    assert "#omp" in output and "#codex" in output and "#claude" in output, output

    # A real PTY exercises selection and argument forwarding.
    machine.succeed("su - testuser -c 'python ${./check-picker.py}'")
  '';
}
