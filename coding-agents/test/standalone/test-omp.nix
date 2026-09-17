{ ai }:
let
  common = import ./common.nix;
  skillEntries = builtins.readDir "${ai.inputs.juspay-skills}/skills";
  bundledSkills = builtins.filter (name: skillEntries.${name} == "directory")
    (builtins.attrNames skillEntries);
in
{
  name = "omp";

  nodes.machine = { pkgs, ... }: {
    imports = [ common.baseNode ];
    environment.systemPackages = [
      ai.legacyPackages.${pkgs.stdenv.hostPlatform.system}.juspay.omp

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

      # Asks OMP which Agent Plugins packages contributed an MCP server, the
      # only way omp 18.2 answers that question without a TTY — see the comment
      # on `plugin_mcp_data_dirs()` below for why this roundabout probe is the
      # surface and not `/mcp list`.
      #
      # A full session start is what runs MCP discovery (ACP does not: an ACP
      # client owns its own MCP servers). The session then dies for want of a
      # reachable gateway — there is no network in this VM — which is fine and
      # ignored: discovery runs first, and it is discovery we are reading.
      (pkgs.writeShellScriptBin "omp-plugin-mcp-data" ''
        set -u
        cd "$(mktemp -d)"
        timeout 180 omp --mode rpc -p hi </dev/null >/dev/null 2>&1 || true
        ls "$HOME/.omp/plugins/data" 2>/dev/null || true
      '')
    ];
    environment.variables.LITELLM_API_KEY = "test-api-key";
  };

  testScript = ''
    import json
    import shlex

    ${common.testPreamble}

    CONFIG = "/home/testuser/.omp/agent/config.yml"

    def loaded_skills():
        """The skills OMP itself reports having loaded.

        OMP's discovery protocol changes independently of our plugin contents.
        Read the actual session commands, not generated wrapper shell source.
        Skill discovery happens before any model call, so no network is needed.
        """
        return set(machine.succeed("su - testuser -c omp-list-skills").split())

    def plugin_mcp_data_dirs():
        """Per-plugin data directories omp created for Agent Plugins MCP servers.

        This is evidence by side effect, and deliberately so: omp 18.2 has no
        headless way to print the MCP servers it discovered. `/mcp list` outside
        the TUI (ACP, `--mode rpc`) reads only `~/.omp/agent/mcp.json` and
        `.omp/mcp.json` and says "No MCP servers configured" for everything
        else; the TUI's own `/mcp` is the one listing that consults the live
        manager, and connection-status events are gated behind `hasUI`. So there
        is nothing to grep for.

        What there is, is `<plugins>/data/<plugin>-<digest>`: the Agent Plugins
        provider creates that directory — and *only* creates it — after it has
        parsed a plugin root's `plugin.json`, read its `mcp.json`, and found a
        stdio server in it, because the spec requires the data dir to exist
        before any plugin subprocess launches. Its appearance therefore means
        omp registered kolu's stdio MCP server from the `-e` root. The `kolu`
        binary is not installed here, so the server cannot actually start; that
        is downstream of this and not what is being asserted.
        """
        return set(machine.succeed("su - testuser -c omp-plugin-mcp-data").split())

    # Runtime opt-out uses the same package, needs no gateway key, and must not
    # seed gateway settings before upstream OMP starts.
    machine.succeed("su - testuser -c 'env -u LITELLM_API_KEY AI_GATEWAY=0 omp --version </dev/null'")
    machine.fail(f"test -e {CONFIG}")

    deprecated = machine.succeed("su - testuser -c 'env -u LITELLM_API_KEY JUSPAY=0 omp --version </dev/null 2>&1'")
    assert deprecated.count("JUSPAY=0 is deprecated; use AI_GATEWAY=0 instead.") == 1, deprecated
    machine.fail(f"test -e {CONFIG}")

    # First launch: this is also what seeds the config asserted on below.
    version = machine.succeed("su - testuser -c 'omp --version'")
    print(f"omp version: {version}")

    # Missing credentials must fail before launching OMP or changing config.
    for key in ["-u LITELLM_API_KEY", "LITELLM_API_KEY="]:
        machine.fail(f"su - testuser -c 'env {key} omp --version </dev/null'")

    def run_as_user(command):
        return machine.succeed("su - testuser -c " + shlex.quote(command))

    def write_config(path, content):
        run_as_user("printf %s " + shlex.quote(content) + " > " + shlex.quote(path))

    def effective_setting(key):
        """The value omp itself resolves for `key`, from the global layer.

        Query the agent's settings resolver rather than matching YAML spelling.
        """
        return json.loads(run_as_user(f"omp config get {key} --json"))["value"]

    assert effective_setting("modelRoles") == {
        "default": "litellm/open-large",
        "smol": "litellm/open-fast",
        "task": "litellm/open-large",
        "slow": "litellm/open-large",
    }
    assert effective_setting("task.showResolvedModelBadge") is True
    machine.fail("test -e /home/testuser/.omp/agent/models.yml")
    # Reproduce an existing wizard config with an expensive primary. Preserve
    # unrelated settings and comments while adding all background roles and the
    # display defaults.
    old_config = "# user settings\nsetupVersion: 2\nmodelRoles:\n  default: 'anthropic/expensive:high' # keep choice\n"
    write_config(CONFIG, old_config)
    run_as_user("omp --version")
    config = machine.succeed(f"cat {CONFIG}")
    for expected in ["# user settings", "setupVersion: 2", "default: 'anthropic/expensive:high' # keep choice", "smol: litellm/open-fast", "task: litellm/open-large", "slow: litellm/open-large", "showResolvedModelBadge: true"]:
        assert expected in config, config

    # A fully configured file must not even be rewritten — /model choices win,
    # and so does the user turning a defaulted setting off. The badge is the
    # only default that is a *choice* rather than a pointer at our gateway, so
    # `false` is the value a user is most likely to have set themselves.
    custom = config.replace("litellm/open-fast", "litellm/custom-fast").replace("litellm/open-large", "litellm/custom-large").replace("showResolvedModelBadge: true", "showResolvedModelBadge: false")
    write_config(CONFIG, custom)
    before = machine.succeed(f"stat -c '%i %Y' {CONFIG}")
    run_as_user("omp --version")
    assert machine.succeed(f"cat {CONFIG}") == custom
    assert machine.succeed(f"stat -c '%i %Y' {CONFIG}") == before
    # The mirror of the fresh-config probe: a setting the wrapper wants on, off
    # by the user's own hand, has to reach omp as off.
    assert effective_setting("task.showResolvedModelBadge") is False

    # Relocated configs get the same migration without changing the normal one.
    run_as_user("mkdir -p /home/testuser/relocated")
    relocated = "/home/testuser/relocated/config.yml"
    write_config(relocated, old_config)
    run_as_user("PI_CODING_AGENT_DIR=/home/testuser/relocated omp --version")
    assert "task: litellm/open-large" in machine.succeed(f"cat {relocated}")
    assert machine.succeed(f"cat {CONFIG}") == custom

    for initial in ["# my settings", "setupVersion: 2\n"]:
        write_config(relocated, initial)
        run_as_user("PI_CODING_AGENT_DIR=/home/testuser/relocated omp --version")
        repaired = machine.succeed(f"cat {relocated}")
        assert initial in repaired
        assert "default: litellm/open-large" in repaired
        assert "slow: litellm/open-large" in repaired

    for invalid in ["modelRoles: [", "modelRoles: []\n", "modelRoles: null\n", "task: []\n", "task: null\n"]:
        write_config(relocated, invalid)
        machine.fail("su - testuser -c 'PI_CODING_AGENT_DIR=/home/testuser/relocated omp --version'")
        assert machine.succeed(f"cat {relocated}") == invalid
    print("✅ existing roles, settings and comments survive migration; invalid config stays untouched")

    # Opting out also preserves existing user configuration without adding the
    # gateway's background roles or display defaults.
    personal = "# personal provider\nmodelRoles:\n  default: openai/my-model\n"
    write_config(relocated, personal)
    roles = json.loads(run_as_user(
        "env -u LITELLM_API_KEY AI_GATEWAY=0 PI_CODING_AGENT_DIR=/home/testuser/relocated "
        "omp config get modelRoles --json"
    ))["value"]
    assert roles == {"default": "openai/my-model"}
    assert machine.succeed(f"cat {relocated}") == personal

    # Check every source skill through the real adapter, plus kolu's separate
    # plugin. An empty or truncated bundle must not lower the expectation.
    skills = loaded_skills()
    expected_skills = set(${builtins.toJSON bundledSkills}) | {"kolu"}
    assert skills == expected_skills, f"expected {sorted(expected_skills)}, loaded {sorted(skills)}"
    assert {"nix-haskell", "kolu"} <= skills
    print(f"OMP loaded all {len(skills)} expected skills")

    # `kolu` in that set is already more than a skill check. A root whose
    # `plugin.json` targets the Agent Plugins standard is handled by the
    # standard provider *exclusively* for skills and MCP — omp's legacy
    # providers are locked out of both surfaces for such a root — and the same
    # classification gates both. So the kolu skill arriving at all means omp
    # accepted kolu's manifest and read the package as a standard one.
    #
    # The MCP half then shows up as omp provisioning that package's data
    # directory; see `plugin_mcp_data_dirs()`.
    data_dirs = plugin_mcp_data_dirs()
    if not any(d.startswith("kolu-") for d in data_dirs):
        raise Exception(f"omp registered no MCP server from kolu's plugin root (data dirs: {sorted(data_dirs)})")
    print(f"✅ omp registered kolu's MCP server from its plugin root ({sorted(data_dirs)})")
  '';
}
