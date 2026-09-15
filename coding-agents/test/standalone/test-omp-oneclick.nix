{ ai }:
let
  common = import ./common.nix;
in
{
  name = "omp-oneclick";

  nodes.machine = { pkgs, ... }: {
    imports = [ common.baseNode ];
    environment.systemPackages = [
      ai.packages.${pkgs.stdenv.hostPlatform.system}.omp-juspay-oneclick
    ];
    environment.variables.LITELLM_API_KEY = "test-api-key";
  };

  testScript = ''
    ${common.testPreamble}
    ${common.probe { }}

    version = machine.succeed("su - testuser -c 'omp --version'")
    print(f"omp version: {version}")

    script = wrapper_script("omp")
    for setting in ["export LITELLM_BASE_URL=https://grid.ai.juspay.net", "export LITELLM_API_KEY"]:
        if setting not in script:
            raise Exception(f"{setting!r} not found in wrapper")
    print("✅ wrapper points omp at the gateway")

    # The wrapper hands omp a temp agent dir with the skills config and the
    # catalog's recommended models, and nothing else: the model list itself is the
    # gateway's, discovered at runtime, so a vendored models file must not reappear.
    agent_dir = machine.succeed("ls -d /tmp/omp-agent-*").split()[0]
    machine.fail(f"test -e {agent_dir}/models.yml")
    machine.fail(f"test -L {agent_dir}/config.yml")

    config = machine.succeed(f"cat {agent_dir}/config.yml")
    if "default: litellm/glm-latest" not in config:
        raise Exception("config.yml does not carry the catalog's default model")
    skills = re.search(r"customDirectories:\s*\n\s*-\s*(\S+)", config)
    if skills is None:
        raise Exception("config.yml does not point at the vendored skills")
    check_skills(skills.group(1))
    print(f"✅ omp gets the catalog at runtime, roles and skills via {agent_dir}")
  '';
}
