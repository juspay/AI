# Shared test infrastructure for home-manager module tests
{ home-manager, oc }:
{
  baseNode = { pkgs, ... }: {
    imports = [ home-manager.nixosModules.home-manager ];
    users.users.testuser = { isNormalUser = true; uid = 1000; };
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.testuser = {
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

  testPreamble = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")
    machine.succeed("loginctl enable-linger testuser")
  '';
}
