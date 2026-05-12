{ oc }:
let common = import ./common.nix;
in
{
  name = "opencode-oneclick";

  nodes.machine = { pkgs, ... }: {
    imports = [ common.baseNode ];
    environment.systemPackages = [
      oc.packages.${pkgs.stdenv.hostPlatform.system}.opencode-juspay-oneclick
    ];
    environment.variables.JUSPAY_API_KEY = "test-api-key";
  };

  testScript = ''
    import json
    import re
    import shlex

    ${common.testPreamble}

    # Test version (verifies opencode runs with bundled config)
    version = machine.succeed("su - testuser -c 'opencode --version'")
    print(f"OpenCode version: {version}")

    # Verify skills are bundled by checking OPENCODE_CONFIG_DIR in wrapper
    opencode_bin = machine.succeed("which opencode").strip()
    print(f"OpenCode binary: {opencode_bin}")

    # Check the wrapper script contains OPENCODE_CONFIG_DIR
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

    # Verify config contents
    config_file = machine.succeed(f"cat {shlex.quote(config_path)}")
    config = json.loads(config_file)
    if "litellm" in config.get("provider", {}):
        print("✅ Juspay provider configuration found")
    else:
        raise Exception("Juspay provider configuration not found")

    print("✅ All oneclick package tests passed")
  '';
}
