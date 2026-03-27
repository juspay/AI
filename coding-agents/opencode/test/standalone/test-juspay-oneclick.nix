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

    # Extract the config dir path from wrapper
    match = re.search(r'OPENCODE_CONFIG_DIR[= ]([^\s\n]+)', wrapper_content)
    if match:
        config_dir = match.group(1).strip("'\"")
        print(f"Config dir: {config_dir}")

        # Check skills exist
        skills_path = f"{config_dir}/skills"
        machine.succeed(f"test -d {skills_path}")
        print(f"✅ Skills directory exists: {skills_path}")

        machine.succeed(f"test -f {skills_path}/nix-flake/SKILL.md")
        print("✅ nix-flake skill exists")

        machine.succeed(f"test -f {skills_path}/nix-haskell/SKILL.md")
        print("✅ nix-haskell skill exists")
    else:
        raise Exception("Could not find OPENCODE_CONFIG_DIR path in wrapper")

    # Verify config file exists
    config_path = f"{config_dir}/opencode.json"
    machine.succeed(f"test -f {config_path}")
    print("✅ Config file exists in config dir")

    # Verify config contents
    config_file = machine.succeed(f"cat {config_path}")
    config = json.loads(config_file)
    if "litellm" in config.get("provider", {}):
        print("✅ Juspay provider configuration found")
    else:
        raise Exception("Juspay provider configuration not found")

    print("✅ All oneclick package tests passed")
  '';
}
