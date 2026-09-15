{ ai }:
let
  common = import ./common.nix;
in
{
  name = "pi-oneclick";

  nodes.machine = { pkgs, ... }: {
    imports = [ common.baseNode ];
    environment.systemPackages = [
      ai.packages.${pkgs.stdenv.hostPlatform.system}.pi-juspay-oneclick
    ];
    environment.variables.JUSPAY_API_KEY = "test-api-key";
  };

  testScript = ''
    ${common.testPreamble}
    ${common.probe { imports = [ "json" ]; }}

    version = machine.succeed("su - testuser -c 'pi --version'")
    print(f"pi version: {version}")

    script = wrapper_script("pi")
    if "PI_CODING_AGENT_DIR" not in script:
        raise Exception("PI_CODING_AGENT_DIR not set in wrapper")

    skill_match = re.search(r"--skill (/nix/store/\S+)", script)
    if skill_match is None:
        raise Exception("wrapper does not pass --skill")
    check_skills(skill_match.group(1))

    # Running the wrapper is what proves the wiring: pi was handed a temporary
    # agent dir holding the generated model file, linked from the store because
    # pi only reads it.
    agent_dir = machine.succeed("ls -d /tmp/pi-agent-*").split()[0]
    machine.succeed(f"test -L {agent_dir}/models.json")

    provider = json.loads(machine.succeed(f"cat {agent_dir}/models.json"))["providers"]["litellm"]
    if provider["baseUrl"] != "https://grid.ai.juspay.net":
        raise Exception(f"unexpected gateway: {provider['baseUrl']}")
    if not any(model["id"] == "glm-latest" for model in provider["models"]):
        raise Exception("glm-latest missing from the generated model list")
    print(f"✅ pi receives {len(provider['models'])} catalog models via {agent_dir}")
  '';
}
