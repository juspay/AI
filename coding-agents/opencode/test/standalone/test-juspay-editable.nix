{ oc }:
let common = import ./common.nix;
in
{
  name = "opencode-init";

  nodes.machine = { pkgs, ... }: {
    imports = [ common.baseNode ];
    environment.systemPackages = [
      oc.packages.${pkgs.stdenv.hostPlatform.system}.opencode-juspay-editable
    ];
  };

  testScript = ''
    import json

    ${common.testPreamble}

    config_path = "/home/testuser/.config/opencode/opencode.json"

    # Verify config doesn't exist initially
    machine.fail(f"test -f {config_path}")

    # First run should create the config file
    version = machine.succeed("su - testuser -c 'opencode --version'")
    print(f"OpenCode version: {version}")

    # Verify config file was created
    machine.succeed(f"test -f {config_path}")
    print("✅ Config file created on first run")

    # Verify config contents
    config_file = machine.succeed(f"su - testuser -c 'cat {config_path}'")
    print(f"Config file contents: {config_file}")

    config = json.loads(config_file)
    if "litellm" in config.get("provider", {}):
        print("✅ Juspay provider configuration found in config")
    else:
        raise Exception("Juspay provider configuration not found")

    # Store original modification time
    orig_mtime = machine.succeed(f"stat -c %Y {config_path}").strip()

    # Second run should NOT overwrite the config
    machine.succeed("su - testuser -c 'opencode --version'")

    new_mtime = machine.succeed(f"stat -c %Y {config_path}").strip()

    if orig_mtime == new_mtime:
        print("✅ Config file not overwritten on subsequent run")
    else:
        raise Exception("Config file was unexpectedly modified")

    print("✅ All default package tests passed")
  '';
}
