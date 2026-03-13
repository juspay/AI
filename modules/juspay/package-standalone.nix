{ pkgs, lib }:
let
  juspaySettings = import ./settings.nix;
  jsonFormat = pkgs.formats.json { };
  configFile = jsonFormat.generate "opencode.json" ({
    "$schema" = "https://opencode.ai/config.json";
  } // juspaySettings);
in
pkgs.runCommand "opencode-juspay-standalone" {
  nativeBuildInputs = [ pkgs.makeWrapper ];
  meta.mainProgram = "opencode";
} ''
  mkdir -p $out/bin
  makeWrapper ${lib.getExe pkgs.opencode} $out/bin/opencode \
    --run 'config_dir="$HOME/.config/opencode"; config_file="$config_dir/opencode.json"; if [ ! -f "$config_file" ]; then mkdir -p "$config_dir"; cp ${configFile} "$config_file"; chmod u+w "$config_file"; fi'
''
