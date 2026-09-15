# Renders opencode.json: the base settings, then the Juspay layer (unless the
# caller opts out with `juspay = false`), then whatever the caller adds on top.
# The packaged variants and the Home Manager module both go through here, so the
# composition rule has one owner.
{ pkgs, juspay ? true, settings ? { } }:
let
  jsonFormat = pkgs.formats.json { };
in
jsonFormat.generate "opencode.json" ({
  "$schema" = "https://opencode.ai/config.json";
} // (import ../settings) // (if juspay then import ../settings/juspay.nix else { }) // settings)
