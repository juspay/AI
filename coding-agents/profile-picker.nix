# Resolve profiles at build time; runtime selection only dispatches launchers.
{ lib, writeShellApplication, profiles, launchers }:
let
  names = builtins.attrNames profiles;
  choices = lib.imap1 (i: name: { inherit i name; }) names;
in
writeShellApplication {
  name = "ai";
  text = ''
    launch() {
      case "$1" in
        ${lib.concatMapStringsSep "\n" (name: ''
          ${name}) shift; exec ${lib.getExe launchers.${name}.picker} "$@" ;;
        '') names}
        *) echo 'Invalid AI_PROFILE; valid values: ${lib.concatStringsSep ", " names}.' >&2; exit 1 ;;
      esac
    }
    if [ "''${AI_PROFILE+x}" = x ]; then
      launch "$AI_PROFILE" "$@"
    fi
    if [ ! -t 0 ]; then
      echo 'Set AI_PROFILE (${lib.concatStringsSep ", " names}), or run nix run github:juspay/AI#<profile>.' >&2
      exit 1
    fi
    printf '%s\n' 'Choose a profile:' ${lib.concatMapStringsSep " " (c: lib.escapeShellArg "  ${toString c.i}) ${c.name}: ${profiles.${c.name}.description}") choices} >&2
    while true; do
      printf 'Profile (name or number; q to quit): ' >&2
      read -r choice || exit 1
      case "$choice" in
        ${lib.concatMapStringsSep "\n" (c: ''
          ${toString c.i}|${c.name}) launch ${c.name} "$@" ;;
        '') choices}
        q|quit) exit 0 ;;
        *) echo 'Valid profiles: ${lib.concatStringsSep ", " names}, or q to quit.' >&2 ;;
      esac
    done
  '';
}
