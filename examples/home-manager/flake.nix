{
  description = "Example Home Manager configuration with OpenCode Juspay";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    oc.url = "github:juspay/oc";
  };

  outputs = { self, nixpkgs, home-manager, oc }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations.example = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          oc.homeModules.default

          {
            home = {
              username = "testuser";
              homeDirectory = "/home/testuser";
              stateVersion = "24.05";
            };
          }
        ];
      };

      checks.${system} = {
        opencode-home-manager-test = pkgs.testers.runNixOSTest {
          name = "opencode-home-manager";

          nodes.machine = { ... }: {
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

                programs.opencode.package = oc.packages.${system}.default;
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
            machine.start()
            machine.wait_for_unit("multi-user.target")

            machine.succeed("loginctl enable-linger testuser")

            # Use su - to get proper PATH from home-manager bash profile
            version = machine.succeed("su - testuser -c 'opencode --version'")
            print(f"OpenCode version: {version}")

            config_file = machine.succeed("su - testuser -c 'cat ~/.config/opencode/opencode.json'")
            print(f"Config file contents: {config_file}")

            if "litellm" in config_file:
                print("✅ Juspay provider configuration found in config")
            else:
                raise Exception("Juspay provider configuration not found")

            print("✅ OpenCode home-manager module configured correctly")
          '';
        };
      };
    };
}
