{ oc, home-manager }:
let common = import ./common.nix { inherit home-manager oc; };
in
{
  name = "opencode-home-manager";

  nodes.machine = { pkgs, ... }: {
    imports = [ common.baseNode ];
    home-manager.users.testuser.imports = [ oc.homeModules.opencode-juspay ];
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
    if "litellm" in config.get("provider", {}):
        print("✅ Juspay provider configuration found in config")
    else:
        raise Exception("Juspay provider configuration not found")

    print("✅ OpenCode home-manager module configured correctly")
  '';
}
