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

    # First launch: this is also what seeds the config asserted on below.
    version = machine.succeed("su - testuser -c 'omp --version'")
    print(f"omp version: {version}")

    script = wrapper_script("omp")
    for setting in ["export LITELLM_BASE_URL=https://grid.ai.juspay.net", "export LITELLM_API_KEY", "export OMP_SKIP_SETUP=1"]:
        if setting not in script:
            raise Exception(f"{setting!r} not found in wrapper")
    print("✅ wrapper points omp at the gateway")

    # Extensions reach omp on the command line, not through a config file: `-e`
    # composes with whatever `extensions:` the user writes, where a generated
    # `extensions:` would be replaced wholesale by theirs. Check the flags name
    # roots that actually exist — a stale or empty path would load nothing, and
    # omp says nothing about it.
    #
    # There are exactly two, in a fixed order, and they are different kinds of
    # thing: our own composed bundle, then kolu's Agent Plugins package taken
    # verbatim out of juspay/kolu.
    # Anchored on /nix/store so the `[ ! -e "$agent_dir/…" ]` test above — the
    # other `-e` in this script, and a different `-e` entirely — cannot match.
    roots = re.findall(r'-e "(/nix/store/[^"]+)"', script)
    if len(roots) != 2:
        raise Exception(f"expected two -e roots in the wrapper, got {roots}:\n{script}")
    bundle, kolu_root = roots
    if not bundle.endswith("-omp-juspay-skills-plugin"):
        raise Exception(f"first -e root is not this repo's skills bundle: {bundle}")
    machine.succeed(f"test -d {bundle}/skills")
    print(f"✅ wrapper loads this repo's skills with -e {bundle}")

    # kolu is no longer harvested into our bundle — if it reappears there, the
    # standard package below is being shadowed by a copy nobody maintains.
    machine.fail(f"test -e {bundle}/skills/kolu")

    # The kolu root is a whole Agent Plugins 1.0.0 package, and every file omp's
    # standard provider reads out of it has to be present: the manifest that
    # classifies the root, the MCP document beside it, and the skill.
    for rel in ["plugin.json", "mcp.json", "skills/kolu/SKILL.md"]:
        machine.succeed(f"test -f {kolu_root}/{rel}")
    mcp = json.loads(machine.succeed(f"cat {kolu_root}/mcp.json"))
    if "kolu" not in mcp.get("mcpServers", {}):
        raise Exception(f"kolu's mcp.json no longer declares a `kolu` server:\n{mcp}")
    print(f"✅ wrapper loads kolu's agent plugin with -e {kolu_root}")

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
