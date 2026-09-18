# Shared VM setup only. Agent discovery protocols belong in their own tests.
{
  # Simulate a rebuild with new plugin store paths but the same profile contents.
  updatedLaunchers = ai: pkgs: ai.lib.mkLaunchers {
    inherit pkgs;
    profile = ai.profiles.juspay // {
      plugins = map (plugin: pkgs.runCommand "updated-plugin" { } ''
        cp -r ${plugin} "$out"
        chmod u+w "$out"
        touch "$out/rebuild-marker"
      '') ai.profiles.juspay.plugins;
    };
  };

  baseNode = {
    users.users.testuser = { isNormalUser = true; uid = 1000; };
    system.stateVersion = "24.05";
  };

  testPreamble = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")
    machine.succeed("loginctl enable-linger testuser")
  '';
}
