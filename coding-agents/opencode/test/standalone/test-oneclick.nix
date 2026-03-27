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

    # Extract config dir path
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

        # Verify config file exists
        config_path = f"{config_dir}/opencode.json"
        machine.succeed(f"test -f {config_path}")
        print("✅ Config file exists in config dir")

        # Verify NO Juspay provider in config
        config_file = machine.succeed(f"cat {config_path}")
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
    else:
        raise Exception("Could not find OPENCODE_CONFIG_DIR path in wrapper")

    print("✅ All opencode-oneclick (no Juspay) tests passed")
  '';
}
