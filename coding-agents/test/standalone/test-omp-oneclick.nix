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

      # Asks OMP which skills it loaded, by driving a real session over ACP and
      # reading the /skill:<name> command it registers per discovered skill.
      # Lives here rather than inline in the test script because it has to reach
      # OMP through the wrapper — the wrapper is what writes the config.yml
      # under test, so anything that bypasses it proves nothing.
      (pkgs.writeShellScriptBin "omp-list-skills" ''
        set -u
        cd "$(mktemp -d)"
        {
          printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":1,"clientCapabilities":{"fs":{"readTextFile":false,"writeTextFile":false}}}}'
          sleep 3
          printf '%s\n' "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"session/new\",\"params\":{\"cwd\":\"$PWD\",\"mcpServers\":[]}}"
          sleep 10
        } | timeout 40 omp acp 2>/dev/null \
          | grep -o '"name":"skill:[^"]*"' | sed 's/.*skill://;s/"$//' | sort -u
      '')
    ];
    environment.variables.LITELLM_API_KEY = "test-api-key";
  };

  testScript = ''
    ${common.testPreamble}
    ${common.probe}

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

    # Skills reach omp as a plugin package listed under `extensions:`, not as a
    # bare `skills.customDirectories`. The old key must be gone, or stale wiring
    # would survive here unnoticed.
    if "customDirectories" in config:
        raise Exception("config.yml still uses skills.customDirectories")
    if not re.search(r"extensions:\s*\n\s*-\s*(\S+)", config):
        raise Exception("config.yml does not list the skills plugin under extensions")
    print(f"✅ omp gets the catalog at runtime, roles and the skills plugin via {agent_dir}")

    # The assertion that matters, and the only one on omp's side of the wiring:
    # what did omp actually load? Everything above reads a file we generated.
    skills = loaded_skills()
    missing = [s for s in PROMISED_SKILLS if s not in skills]
    if missing:
        raise Exception(f"omp did not load {missing} via extensions: (loaded {sorted(skills)})")
    print(f"✅ omp loaded {len(skills)} skills through extensions:, including {PROMISED_SKILLS}")
  '';
}
