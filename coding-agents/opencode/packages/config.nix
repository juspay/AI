{ pkgs }:
let
  juspaySettings = import ../../../juspay/settings.nix;
  jsonFormat = pkgs.formats.json { };
in
jsonFormat.generate "opencode.json" ({
  "$schema" = "https://opencode.ai/config.json";
} // juspaySettings)
