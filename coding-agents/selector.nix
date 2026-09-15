# The flake's front door: `nix run github:juspay/AI` offers every packaged
# variant in one menu. The variant table passed in is the only datum — labels
# and dispatch arms are both rendered from it, so a variant cannot appear in the
# menu and be missing from the dispatch (or vice versa).
{ pkgs, lib, variants }:
let
  label = v: "${v.name} — ${v.description}";
  labels = map (v: "    ${lib.escapeShellArg (label v)}") variants;
  menu = lib.concatStringsSep " \\\n" labels;
  arms = lib.concatMapStrings
    (v: "    ${lib.escapeShellArg (label v)}) exec ${lib.getExe v.package} \"$@\" ;;\n")
    variants;
in
pkgs.writeShellApplication {
  name = "ai";
  runtimeInputs = [ pkgs.gum ];
  text = ''
    choice=$(gum choose --header "Choose a coding agent variant:" \
${menu})
    case "$choice" in
${arms}    *) echo "No selection made."; exit 1 ;;
    esac
  '';
}
