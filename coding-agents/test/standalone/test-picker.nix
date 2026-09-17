{ ai }:
let
  common = import ./common.nix;
in
{
  name = "picker";
  nodes.machine = { pkgs, ... }: {
    imports = [ common.baseNode ];
    environment.systemPackages = [ ai.packages.${pkgs.stdenv.hostPlatform.system}.default ai.packages.${pkgs.stdenv.hostPlatform.system}.juspay pkgs.python3 ];
  };
  testScript = ''
    ${common.testPreamble}

    status, output = machine.execute("su - testuser -c 'ai --version </dev/null 2>&1'")
    assert status != 0
    assert "Set AI_PROFILE (juspay, kolu, vanilla)" in output, output
    assert "nix run github:juspay/AI#<profile>" in output, output

    status, output = machine.execute("su - testuser -c 'ai-juspay --version </dev/null 2>&1'")
    assert status == 1
    assert "Set AI_HARNESS to omp, codex, or claude" in output, output
    assert "github:" not in output, output
    machine.succeed("su - testuser -c 'AI_PROFILE=vanilla AI_HARNESS=omp ai --version </dev/null'")
    for override in ["AI_PROFILE=bad", "AI_PROFILE=", "AI_PROFILE=vanilla AI_HARNESS=bad", "AI_PROFILE=vanilla AI_HARNESS="]:
        status, output = machine.execute(f"su - testuser -c '{override} ai --version </dev/null 2>&1'")
        assert status == 1 and "valid values:" in output, output

    # A real PTY exercises selection and argument forwarding.
    machine.succeed("su - testuser -c 'python ${./check-picker.py}'")
  '';
}
