let
  sharedLib = import ../../lib.nix;
in
{
  inherit (sharedLib) checkApiKey;

  mkInitScript = configFile: ''
    ${sharedLib.checkApiKey}
    config_dir="$HOME/.config/opencode"
    config_file="$config_dir/opencode.json"
    if [ ! -f "$config_file" ]; then
      mkdir -p "$config_dir"
      cp ${configFile} "$config_file"
      chmod u+w "$config_file"
    fi
  '';

  mkConfigDir = { pkgs, configFile, skillsSrc }:
    pkgs.runCommand "opencode-config-dir" { } ''
      mkdir -p $out
      ln -s ${configFile} $out/opencode.json
      ln -s ${skillsSrc}/skills $out/skills
    '';
}
