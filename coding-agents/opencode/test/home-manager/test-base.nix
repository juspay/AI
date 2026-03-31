{ oc, home-manager }:
let common = import ./common.nix { inherit home-manager oc; };
in
{
  name = "opencode-base-module";

  nodes.machine = { pkgs, ... }: {
    imports = [ common.baseNode ];
    home-manager.users.testuser.imports = [ oc.homeModules.opencode ];
  };

  testScript = ''
    import json

    ${common.testPreamble}

    version = machine.succeed("su - testuser -c 'opencode --version'")
    print(f"OpenCode version: {version}")

    config_path = "/home/testuser/.config/opencode/opencode.json"
    config_file = machine.succeed(f"su - testuser -c 'cat {config_path}'")
    print(f"Config file contents: {config_file}")

    config = json.loads(config_file)

    # Verify NO Juspay provider
    if "litellm" not in config.get("provider", {}):
        print("✅ No Juspay provider in config (as expected)")
    else:
        raise Exception("Juspay provider found in base module")

    # Verify base settings
    if config.get("autoupdate") == True:
        print("✅ autoupdate enabled")
    else:
        raise Exception("autoupdate not found in config")

    # Verify skills are wired via nix-agent-wire
    skills_dir = "/home/testuser/.config/opencode/skills"

    machine.succeed(f"test -f {skills_dir}/nix-flake/SKILL.md")
    print("✅ nix-flake skill exists")

    machine.succeed(f"test -f {skills_dir}/nix-haskell/SKILL.md")
    print("✅ nix-haskell skill exists")

    machine.succeed(f"test -f {skills_dir}/nix-ci/SKILL.md")
    print("✅ nix-ci skill exists")

    machine.succeed(f"test -f {skills_dir}/vhs/SKILL.md")
    print("✅ vhs skill exists")

    print("✅ All base module tests passed")
  '';
}
