{ oc }:
{
  name = "claude-code-juspay-oneclick";

  nodes.machine = { pkgs, ... }: {
    users.users.testuser = {
      isNormalUser = true;
      uid = 1000;
    };

    environment.systemPackages = [
      oc.packages.${pkgs.stdenv.hostPlatform.system}.claude-code-juspay-oneclick
    ];

    environment.variables.JUSPAY_API_KEY = "test-api-key";

    system.stateVersion = "24.05";
  };

  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")

    machine.succeed("loginctl enable-linger testuser")

    # Test version (verifies claude runs with Juspay env)
    version = machine.succeed("su - testuser -c 'claude --version'")
    print(f"Claude Code version: {version}")

    # Verify wrapper sets Juspay environment variables
    claude_bin = machine.succeed("which claude").strip()
    wrapper_content = machine.succeed(f"cat {claude_bin}")

    if "ANTHROPIC_BASE_URL" in wrapper_content:
        print("✅ ANTHROPIC_BASE_URL is set in wrapper")
    else:
        raise Exception("ANTHROPIC_BASE_URL not found in wrapper")

    if "grid.ai.juspay.net" in wrapper_content:
        print("✅ Juspay grid URL found in wrapper")
    else:
        raise Exception("Juspay grid URL not found in wrapper")

    # Verify skills are symlinked into ~/.claude/skills/
    skills_dir = "/home/testuser/.claude/skills"

    machine.succeed(f"test -d {skills_dir}")
    print(f"✅ Skills directory exists: {skills_dir}")

    machine.succeed(f"test -f {skills_dir}/nix-flake/SKILL.md")
    print("✅ nix-flake skill exists")

    machine.succeed(f"test -f {skills_dir}/nix-haskell/SKILL.md")
    print("✅ nix-haskell skill exists")

    print("✅ All claude-code-juspay-oneclick tests passed")
  '';
}
