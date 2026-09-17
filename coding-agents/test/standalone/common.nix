# Shared test infrastructure for the wrapper package test. A wrapper is
# exercised through the agent it fronts, so what is shared here is the machine
# setup and the python that reads a wrapper's shell source.
let
  # The python the wrapper test starts with. A script needing imports adds them
  # itself — the test driver lints for unused imports, so a shared pool would
  # make one script's imports another script's problem.
  probe = ''
    def wrapper_script(agent):
        """Shell source of the installed wrapper for `agent`."""
        return machine.succeed(f"cat $(which {agent})")

    # The skills this flake promises its users. Not a sample: each name is a
    # contract, and one per source, so that a source dropping out upstream fails
    # the build instead of silently shipping a smaller agent. juspay/skills has
    # already lost a skill this way once (`nix-flake`), and it now arrives
    # through an unattended nightly lock bump, so nothing else would catch it.
    # Add a name here only if you mean to promise it.
    #
    # `kolu` is the odd one: the first two are copied into this repo's bundle,
    # while kolu ships its own Agent Plugins package that omp loads whole. Its
    # presence here checks discovery of that separate root; test-omp.nix also
    # verifies all skills in our composed Agent Plugins bundle.
    PROMISED_SKILLS = ["nix-haskell", "frontend-design", "kolu"]
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

  inherit probe;
}
