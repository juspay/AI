{ ai }:
let
  common = import ./common.nix;
in
{
  name = "omp-standalone";

  nodes.machine = { pkgs, ... }: {
    imports = [ common.baseNode ];
    environment.systemPackages = [
      ai.packages.${pkgs.stdenv.hostPlatform.system}.omp-standalone
    ];
    # No gateway credentials: standalone must not acquire or require them.
  };

  testScript = ''
    import json
    import shlex

    ${common.testPreamble}

    def run_as_user(command):
        return machine.succeed("su - testuser -c " + shlex.quote(command))

    config = "/home/testuser/.omp/agent/config.yml"
    run_as_user("omp --version </dev/null")
    machine.fail(f"test -e {config}")

    # A provider chosen by the user remains theirs; no gateway roles are added.
    custom = "# personal provider\nmodelRoles:\n  default: openai/my-model\n"
    run_as_user("mkdir -p ~/.omp/agent")
    run_as_user("printf %s " + shlex.quote(custom) + " > " + shlex.quote(config))
    roles = json.loads(run_as_user("omp config get modelRoles --json"))["value"]
    assert roles == {"default": "openai/my-model"}
    assert machine.succeed(f"cat {config}") == custom
  '';
}
