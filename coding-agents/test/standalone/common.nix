# Shared test infrastructure for the wrapper package tests. A wrapper is
# exercised through the agent it fronts, so what is shared here is the machine
# setup and the python that reads a wrapper's shell source.
let
  inherit (builtins) concatStringsSep lessThan map sort;

  # The python every wrapper test starts with. `imports` adds the stdlib modules
  # the calling script itself needs, on top of the ones these helpers use (`json`
  # among them, since check_skills_plugin parses the plugin manifest) — each
  # script then imports exactly what it references.
  probe = { imports ? [ ] }: ''
    ${concatStringsSep "" (map (module: "import ${module}\n") (sort lessThan ([ "json" "re" "shlex" ] ++ imports)))}
    def wrapper_script(agent):
        """Shell source of the installed wrapper for `agent`."""
        return machine.succeed(f"cat $(which {agent})")

    def linked_path(script, link_name):
        """Store path the wrapper symlinks as <link_name> in its config dir."""
        match = re.search(r'ln -s (\S+) "[^"]*/' + re.escape(link_name) + '"', script)
        if match is None:
            raise Exception(f"wrapper does not link {link_name}")
        return match.group(1)

    def check_skills(skills_path):
        """The store-built skill directory the wrapper hands the agent.

        One skill per composed source: nix-haskell from juspay/skills,
        frontend-design from anthropics/skills, kolu from juspay/kolu. OMP
        discovers these one level down and non-recursively, so the SKILL.md
        must sit exactly here.
        """
        machine.succeed(f"test -d {shlex.quote(skills_path)}")
        for skill in ["nix-haskell", "frontend-design", "kolu"]:
            machine.succeed(f"test -f {shlex.quote(skills_path)}/{skill}/SKILL.md")
        print(f"✅ Skills bundled: {skills_path}")

    def check_skills_plugin(plugin_path):
        """The OMP *plugin* package: a manifest next to the skills it declares.

        Without the manifest OMP's loader skips the package outright, so the
        skills would silently not load — assert on it, not just on the skills.
        """
        machine.succeed(f"test -f {shlex.quote(plugin_path)}/package.json")
        manifest = json.loads(machine.succeed(f"cat {shlex.quote(plugin_path)}/package.json"))
        if manifest.get("omp", {}).get("skills") != "./skills":
            raise Exception(f"plugin manifest does not declare skills: {manifest}")
        check_skills(f"{plugin_path}/skills")
        print(f"✅ OMP plugin package: {plugin_path}")
  '';

  # The body of an opencode *-oneclick test. Both flavours do the same three
  # things — point OPENCODE_CONFIG_DIR at a temp dir, link the generated config
  # and the vendored skills into it, run opencode — and differ only in whether
  # that config is expected to carry the Juspay provider.
  opencodeOneclick = { expectJuspay }: probe { } + ''
    expect_juspay = ${if expectJuspay then "True" else "False"}

    version = machine.succeed("su - testuser -c 'opencode --version'")
    print(f"OpenCode version: {version}")

    script = wrapper_script("opencode")
    if "OPENCODE_CONFIG_DIR" not in script:
        raise Exception("OPENCODE_CONFIG_DIR not set in wrapper")
    print("✅ OPENCODE_CONFIG_DIR is set in wrapper")

    check_skills(linked_path(script, "skills"))
    config_path = linked_path(script, "opencode.json")

    config = json.loads(machine.succeed(f"cat {shlex.quote(config_path)}"))
    if ("litellm" in config.get("provider", {})) != expect_juspay:
        raise Exception(f"Juspay provider present != {expect_juspay}")
    if config.get("autoupdate") is not True:
        raise Exception("base settings missing from the generated config")
    print(f"✅ Juspay provider present: {expect_juspay}")
  '';
in
{
  baseNode = {
    users.users.testuser = { isNormalUser = true; uid = 1000; };
    system.stateVersion = "24.05";
  };

  testPreamble = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")
    machine.succeed("loginctl enable-linger testuser")
  '';

  inherit probe opencodeOneclick;
}
