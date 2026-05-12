{ oc }:
let common = import ./common.nix;
in
{
  name = "opencode-oneclick-no-juspay";

  nodes.machine = { pkgs, ... }: {
    imports = [ common.baseNode ];
    environment.systemPackages = [
      oc.packages.${pkgs.stdenv.hostPlatform.system}.opencode-oneclick
    ];
  };

  testScript = ''
    import json
    import re
    import shlex

    ${common.testPreamble}

    # Test version (verifies opencode runs without JUSPAY_API_KEY)
    version = machine.succeed("su - testuser -c 'opencode --version'")
    print(f"OpenCode version: {version}")

    # Verify OPENCODE_CONFIG_DIR is set in wrapper
    opencode_bin = machine.succeed("which opencode").strip()
    wrapper_content = machine.succeed(f"cat {opencode_bin}")
    if "OPENCODE_CONFIG_DIR" in wrapper_content:
        print("✅ OPENCODE_CONFIG_DIR is set in wrapper")
    else:
        raise Exception("OPENCODE_CONFIG_DIR not found in wrapper")

    # Extract the store paths linked into the runtime OPENCODE_CONFIG_DIR.
    skills_match = re.search(r'ln -s (\S+) "\$OPENCODE_CONFIG_DIR/skills"', wrapper_content)
    config_match = re.search(r'ln -s (\S+) "\$OPENCODE_CONFIG_DIR/opencode\.json"', wrapper_content)
    if not skills_match or not config_match:
        raise Exception("Could not find bundled config or skills path in wrapper")

    skills_path = skills_match.group(1)
    config_path = config_match.group(1)
    print(f"Skills path: {skills_path}")
    print(f"Config path: {config_path}")

    # Check skills exist
    machine.succeed(f"test -d {shlex.quote(skills_path)}")
    print(f"✅ Skills directory exists: {skills_path}")

    machine.succeed(f"test -f {shlex.quote(skills_path)}/nix-flake/SKILL.md")
    print("✅ nix-flake skill exists")

    machine.succeed(f"test -f {shlex.quote(skills_path)}/nix-haskell/SKILL.md")
    print("✅ nix-haskell skill exists")

    # Verify config file exists
    machine.succeed(f"test -f {shlex.quote(config_path)}")
    print("✅ Config file exists in config dir")

    # Verify NO Juspay provider in config
    config_file = machine.succeed(f"cat {shlex.quote(config_path)}")
    config = json.loads(config_file)
    if "litellm" not in config.get("provider", {}):
        print("✅ No Juspay provider in config (as expected)")
    else:
        raise Exception("Juspay provider found in non-Juspay variant")

    # Verify base settings present
    if config.get("autoupdate") == True:
        print("✅ autoupdate enabled")
    else:
        raise Exception("autoupdate not found in config")

    print("✅ All opencode-oneclick (no Juspay) tests passed")
  '';
}
