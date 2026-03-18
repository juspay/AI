{ pkgs, settings ? (import ../settings // import ../settings/juspay.nix) }:
let
  jsonFormat = pkgs.formats.json { };
in
jsonFormat.generate "opencode.json" ({
  "$schema" = "https://opencode.ai/config.json";
} // settings)
