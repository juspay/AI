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
      # Goes through the wrapper on purpose: the wrapper is what writes the
      # config.yml under test, so anything that bypasses it proves nothing.
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

    def loaded_skills():
        """The skills OMP itself reports having loaded.

        Every other assertion in these tests reads a file *we* generate, so they
        all sit on this repo's clock. OMP sits on its own: it ships daily
        through llm-agents -> flake.lock -> an auto-merged bump, and its
        settings schema does move — `skills.customDirectories` -> `extensions:`
        is exactly what this wiring changed to. OMP ignores an unrecognised
        config key silently, so if a future release renames or narrows
        `extensions:`, our config.yml still generates, still looks right, and
        every user gets an agent with no skills at all.

        This is the one check on OMP's side of that boundary, which is why it
        lives beside the omp-list-skills script it drives rather than in the
        shared preamble. It answers "did OMP load these?" rather than "did we
        write the files we think we wrote?". No network needed: skill discovery
        happens before any model call.
        """
        return set(machine.succeed("su - testuser -c omp-list-skills").split())

    version = machine.succeed("su - testuser -c 'omp --version'")
    print(f"omp version: {version}")

    script = wrapper_script("omp")
    for setting in ["export LITELLM_BASE_URL=https://grid.ai.juspay.net", "export LITELLM_API_KEY"]:
        if setting not in script:
            raise Exception(f"{setting!r} not found in wrapper")
    print("✅ wrapper points omp at the gateway")

    # The wrapper hands omp a temp agent dir with the generated config and
    # nothing else: the model list itself is the gateway's, discovered at
    # runtime, so a vendored models file must not reappear.
    agent_dir = machine.succeed("ls -d /tmp/omp-agent-*").split()[0]
    machine.fail(f"test -e {agent_dir}/models.yml")
    machine.fail(f"test -L {agent_dir}/config.yml")

    config = machine.succeed(f"cat {agent_dir}/config.yml")
    if "default: litellm/glm-latest" not in config:
        raise Exception("config.yml does not carry the catalog's default model")
    print(f"✅ omp gets the catalog at runtime and its roles via {agent_dir}")

    # The assertion that matters. Everything above reads something we generated;
    # this asks omp. It subsumes checking that config.yml still says
    # `extensions:` and still points at the plugin — both of those fail here
    # too, verified by negative control, and only this one also catches omp
    # changing what `extensions:` means.
    skills = loaded_skills()
    missing = [s for s in PROMISED_SKILLS if s not in skills]
    if missing:
        raise Exception(f"omp did not load {missing} via extensions: (loaded {sorted(skills)})")
    print(f"✅ omp loaded {len(skills)} skills through extensions:, including {PROMISED_SKILLS}")
  '';
}
