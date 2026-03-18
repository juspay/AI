{ oc, home-manager }:
{
  name = "opencode-home-manager";

  nodes.machine = { pkgs, ... }: {
    imports = [ home-manager.nixosModules.home-manager ];

    users.users.testuser = {
      isNormalUser = true;
      uid = 1000;
    };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.testuser = {
        imports = [ oc.homeModules.default ];

        programs.opencode.package = oc.packages.${pkgs.stdenv.hostPlatform.system}.opencode;
        programs.bash.enable = true;

        home = {
          username = "testuser";
          homeDirectory = "/home/testuser";
          stateVersion = "24.05";
        };
      };
    };

    system.stateVersion = "24.05";
  };

  testScript = ''
    import json

    machine.start()
    machine.wait_for_unit("multi-user.target")

    machine.succeed("loginctl enable-linger testuser")

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
