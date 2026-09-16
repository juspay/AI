{ ai }:
let
  common = import ./common.nix;
in
{
  name = "omp";

  nodes.machine = { pkgs, ... }: {
    imports = [ common.baseNode ];
    environment.systemPackages = [
      ai.packages.${pkgs.stdenv.hostPlatform.system}.default

      # Asks OMP which skills it loaded, by driving a real session over ACP and
      # reading the /skill:<name> command it registers per discovered skill.
      # Goes through the wrapper on purpose: the wrapper is what puts the plugin
      # on omp's command line, so anything that bypasses it proves nothing.
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
    import re

    ${common.testPreamble}
    ${common.probe}

    CONFIG = "/home/testuser/.omp/agent/config.yml"

    def loaded_skills():
        """The skills OMP itself reports having loaded.

        Every other assertion in these tests reads a file *we* generate, so they
        all sit on this repo's clock. OMP sits on its own: upstream cuts several
        releases a week, and each one reaches us as a release-tag bump in
        flake.nix -> flake.lock -> an auto-merged PR. Its CLI surface does move —
        `skills.customDirectories` -> `extensions:` -> `-e` is exactly what this
        wiring has already chased twice. OMP ignores an unrecognised flag
        target silently, so if a future release stops scanning `skills/` beside
        `-e` roots, our wrapper still builds, still looks right, and every user
        gets an agent with no skills at all.

        This is the one check on OMP's side of that boundary, which is why it
        lives beside the omp-list-skills script it drives rather than in the
        shared preamble. It answers "did OMP load these?" rather than "did we
        write the flags we think we wrote?". No network needed: skill discovery
        happens before any model call.
        """
        return set(machine.succeed("su - testuser -c omp-list-skills").split())

    # First launch: this is also what seeds the config asserted on below.
    version = machine.succeed("su - testuser -c 'omp --version'")
    print(f"omp version: {version}")

    script = wrapper_script("omp")
    for setting in ["export LITELLM_BASE_URL=https://grid.ai.juspay.net", "export LITELLM_API_KEY", "export OMP_SKIP_SETUP=1"]:
        if setting not in script:
            raise Exception(f"{setting!r} not found in wrapper")
    print("✅ wrapper points omp at the gateway")

    # Skills reach omp on the command line, not through a config file: `-e`
    # composes with whatever `extensions:` the user writes, where a generated
    # `extensions:` would be replaced wholesale by theirs. Check the flag names
    # a plugin root that actually exists — a stale or empty path would load
    # nothing, and omp says nothing about it.
    match = re.search(r'-e "(/nix/store/\S*-omp-juspay-skills-plugin)"', script)
    if not match:
        raise Exception(f"wrapper does not pass the skills plugin with -e:\n{script}")
    machine.succeed(f"test -d {match.group(1)}/skills")
    print(f"✅ wrapper loads skills with -e {match.group(1)}")

    # The config is the user's own ~/.omp/agent/config.yml now, not a per-run
    # temp dir: sessions, auth and onboarding persist beside it and `/model`
    # writes land somewhere that survives the next launch.
    machine.succeed(f"test -f {CONFIG}")
    config = machine.succeed(f"cat {CONFIG}")
    if "default: litellm/glm-latest" not in config:
        raise Exception(f"config.yml was not seeded with the default model role:\n{config}")
    # The model list itself is the gateway's, discovered at runtime, so a
    # vendored models file must not reappear beside it.
    machine.fail("test -e /home/testuser/.omp/agent/models.yml")
    print("✅ first launch seeds the real agent config with the model roles")

    # Seeded once, never rewritten. This is the whole point of seeding rather
    # than overlaying: a `--config` overlay would sit *above* this file, and the
    # user's own edit — or anything `/model` and `/settings` write here — would
    # look like it silently reverted on the next launch.
    machine.succeed(f"su - testuser -c \"sed -i 's|smol: .*|smol: litellm/edited-by-user|' {CONFIG}\"")
    machine.succeed("su - testuser -c 'omp --version'")
    config = machine.succeed(f"cat {CONFIG}")
    if "smol: litellm/edited-by-user" not in config:
        raise Exception(f"second launch overwrote the user's edit:\n{config}")
    print("✅ a second launch leaves the user's edits alone")

    # The assertion that matters. Everything above reads something we generated;
    # this asks omp. It subsumes checking that the wrapper still passes `-e` and
    # still points at the plugin — both of those fail here too, verified by
    # negative control (dropping `-e` loads none of these skills) — and only
    # this one also catches omp changing what `-e` roots mean for skills.
    skills = loaded_skills()
    missing = [s for s in PROMISED_SKILLS if s not in skills]
    if missing:
        raise Exception(f"omp did not load {missing} via -e (loaded {sorted(skills)})")
    print(f"✅ omp loaded {len(skills)} skills through -e, including {PROMISED_SKILLS}")
  '';
}
