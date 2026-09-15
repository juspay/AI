# Shared test infrastructure for the wrapper package tests. A wrapper is
# exercised through the agent it fronts, so what is shared here is the machine
# setup and the python that reads a wrapper's shell source.
let
  # The python every wrapper test starts with: the helpers below, and the two
  # stdlib modules those helpers reference. A script needing more imports it
  # itself — the test driver lints for unused imports, so a shared pool would
  # make one script's imports another script's problem.
  probe = ''
    import re
    import shlex

    def wrapper_script(agent):
        """Shell source of the installed wrapper for `agent`."""
        return machine.succeed(f"cat $(which {agent})")

    def linked_path(script, link_name):
        """Store path the wrapper symlinks as <link_name> in its config dir."""
        match = re.search(r'ln -s (\S+) "[^"]*/' + re.escape(link_name) + '"', script)
        if match is None:
            raise Exception(f"wrapper does not link {link_name}")
        return match.group(1)

    # The skills this flake promises its users. Not a sample: each name is a
    # contract, and one per composed source, so that a source dropping out
    # upstream fails the build instead of silently shipping a smaller agent.
    # juspay/skills has already lost a skill this way once (`nix-flake`), and it
    # now arrives through an unattended nightly lock bump, so nothing else would
    # catch it. Add a name here only if you mean to promise it.
    PROMISED_SKILLS = ["nix-haskell", "frontend-design", "kolu"]

    def check_skills(skills_path):
        """The store-built skill directory the wrapper hands the agent.

        A file-level check, so it can only speak for agents that take a plain
        directory of skills (opencode). For OMP, ask OMP — see loaded_skills in
        test-omp-oneclick.nix.
        """
        machine.succeed(f"test -d {shlex.quote(skills_path)}")
        for skill in PROMISED_SKILLS:
            machine.succeed(f"test -f {shlex.quote(skills_path)}/{skill}/SKILL.md")
        print(f"✅ Skills bundled: {skills_path}")
  '';

  # The body of an opencode *-oneclick test. Both flavours do the same three
  # things — point OPENCODE_CONFIG_DIR at a temp dir, link the generated config
  # and the store-built skills into it, run opencode — and differ only in whether
  # that config is expected to carry the Juspay provider.
  opencodeOneclick = { expectJuspay }: probe + ''
    import json

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
