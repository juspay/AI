{ oc, home-manager }:
{
  name = "claude-code-juspay-home-manager";

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
        imports = [ oc.homeModules.claude-code-juspay ];

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
    import json

    machine.start()
    machine.wait_for_unit("multi-user.target")

    machine.succeed("loginctl enable-linger testuser")

    version = machine.succeed("su - testuser -c 'claude --version'")
    print(f"Claude Code version: {version}")

    # Verify settings.json contains Juspay env vars
    settings_path = "/home/testuser/.claude/settings.json"
    settings_file = machine.succeed(f"su - testuser -c 'cat {settings_path}'")
    print(f"Settings file contents: {settings_file}")

    settings = json.loads(settings_file)
    env = settings.get("env", {})

    if env.get("ANTHROPIC_BASE_URL") == "https://grid.ai.juspay.net/":
        print("✅ Juspay ANTHROPIC_BASE_URL found in settings")
    else:
        raise Exception(f"Juspay ANTHROPIC_BASE_URL not found in settings env: {env}")

    if "JUSPAY_API_KEY" in settings.get("apiKeyHelper", ""):
        print("✅ apiKeyHelper references JUSPAY_API_KEY")
    else:
        raise Exception(f"apiKeyHelper not configured: {settings.get('apiKeyHelper')}")

    print("✅ Claude Code Juspay home-manager module configured correctly")
  '';
}
