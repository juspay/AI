{ oc, home-manager }:
{
  name = "opencode-with-skills";

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
        imports = [ oc.homeModules.with-skills ];

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

    # Verify skills are wired via nix-agent-wire
    skills_dir = "/home/testuser/.config/opencode/skill"
    
    machine.succeed(f"test -f {skills_dir}/nix-flake/SKILL.md")
    print("✅ nix-flake skill exists")
    
    machine.succeed(f"test -f {skills_dir}/nix-haskell/SKILL.md")
    print("✅ nix-haskell skill exists")
    
    machine.succeed(f"test -f {skills_dir}/nix-ci/SKILL.md")
    print("✅ nix-ci skill exists")
    
    machine.succeed(f"test -f {skills_dir}/vhs/SKILL.md")
    print("✅ vhs skill exists")

    print("✅ All with-skills module tests passed")
  '';
}
