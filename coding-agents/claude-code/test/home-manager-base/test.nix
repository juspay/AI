{ oc, home-manager }:
{
  name = "claude-code-base-module";

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
        imports = [ oc.homeModules.claude-code ];

        programs.claude-code.package = oc.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;
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

    version = machine.succeed("su - testuser -c 'claude --version'")
    print(f"Claude Code version: {version}")

    # Verify skills are wired via nix-agent-wire
    skills_dir = "/home/testuser/.claude/skills"

    machine.succeed(f"test -f {skills_dir}/nix-flake/SKILL.md")
    print("✅ nix-flake skill exists")

    machine.succeed(f"test -f {skills_dir}/nix-haskell/SKILL.md")
    print("✅ nix-haskell skill exists")

    machine.succeed(f"test -f {skills_dir}/nix-ci/SKILL.md")
    print("✅ nix-ci skill exists")

    machine.succeed(f"test -f {skills_dir}/vhs/SKILL.md")
    print("✅ vhs skill exists")

    print("✅ All claude-code base module tests passed")
  '';
}
