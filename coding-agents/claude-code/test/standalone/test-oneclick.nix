{ oc }:
{
  name = "claude-code-oneclick";

  nodes.machine = { pkgs, ... }: {
    users.users.testuser = {
      isNormalUser = true;
      uid = 1000;
    };

    environment.systemPackages = [
      oc.packages.${pkgs.stdenv.hostPlatform.system}.claude-code-oneclick
    ];

    system.stateVersion = "24.05";
  };

  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")

    machine.succeed("loginctl enable-linger testuser")

    # Test version (verifies claude runs)
    version = machine.succeed("su - testuser -c 'claude --version'")
    print(f"Claude Code version: {version}")

    # Verify skills are symlinked into ~/.claude/skills/
    skills_dir = "/home/testuser/.claude/skills"

    machine.succeed(f"test -d {skills_dir}")
    print(f"✅ Skills directory exists: {skills_dir}")

    machine.succeed(f"test -f {skills_dir}/nix-flake/SKILL.md")
    print("✅ nix-flake skill exists")

    machine.succeed(f"test -f {skills_dir}/nix-haskell/SKILL.md")
    print("✅ nix-haskell skill exists")

    # Verify skills are symlinks (pointing to nix store)
    link_target = machine.succeed(f"readlink {skills_dir}/nix-flake").strip()
    if "/nix/store/" in link_target:
        print(f"✅ Skill is a symlink to nix store: {link_target}")
    else:
        raise Exception(f"Skill is not a nix store symlink: {link_target}")

    print("✅ All claude-code-oneclick tests passed")
  '';
}
