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
    environment.variables.JUSPAY_API_KEY = "test-api-key";
  };

  testScript = ''
    ${common.testPreamble}
    ${common.probe { }}

    version = machine.succeed("su - testuser -c 'omp --version'")
    print(f"omp version: {version}")

    script = wrapper_script("omp")
    if "PI_CODING_AGENT_DIR" not in script:
        raise Exception("PI_CODING_AGENT_DIR not set in wrapper")

    # omp only reads models.yml, so the wrapper links it from the store; it
    # rewrites config.yml, so that one has to be a writable copy.
    agent_dir = machine.succeed("ls -d /tmp/omp-agent-*").split()[0]
    machine.succeed(f"test -L {agent_dir}/models.yml")
    machine.fail(f"test -L {agent_dir}/config.yml")

    models = machine.succeed(f"cat {agent_dir}/models.yml")
    if "litellm:" not in models or "baseUrl: https://grid.ai.juspay.net" not in models:
        raise Exception("generated models.yml is missing the Juspay provider")

    config = machine.succeed(f"cat {agent_dir}/config.yml")
    skills = re.search(r"customDirectories:\s*\n\s*-\s*(\S+)", config)
    if skills is None:
        raise Exception("config.yml does not point at the vendored skills")
    check_skills(skills.group(1))
    print(f"✅ omp receives the catalog and skills via {agent_dir}")
  '';
}
