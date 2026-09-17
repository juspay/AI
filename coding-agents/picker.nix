# Selection only: each launcher owns its initialization and plugin protocol.
{ lib, writeShellApplication, omp, codex, claude, profile }:
let
  ownLogin = lib.optionalString ((profile.gateway or null) != null) " (uses its own login)";
in
writeShellApplication {
  name = "ai-${profile.name}";
  text = ''
    launch() {
      case "$1" in
        omp) shift; exec ${lib.getExe omp} "$@" ;;
        codex) shift; exec ${lib.getExe codex} "$@" ;;
        claude) shift; exec ${lib.getExe claude} "$@" ;;
        *) echo 'Invalid AI_HARNESS; valid values: omp, codex, claude.' >&2; exit 1 ;;
      esac
    }
    if [ "''${AI_HARNESS+x}" = x ]; then
      launch "$AI_HARNESS" "$@"
    fi
    if [ ! -t 0 ]; then
      echo 'Choose a harness with nix run github:juspay/AI#${profile.name}.omp, github:juspay/AI#${profile.name}.codex, or github:juspay/AI#${profile.name}.claude.' >&2
      exit 1
    fi

    printf '%s\n' ${lib.escapeShellArg profile.description} 'Choose a coding agent:' '  1) Oh My Pi' '  2) Codex${ownLogin}' '  3) Claude Code${ownLogin}' >&2
    while true; do
      printf 'Agent [1/2/3] (q to quit): ' >&2
      read -r choice
      case "$choice" in
        1|omp) launch omp "$@" ;;
        2|codex) launch codex "$@" ;;
        3|claude) launch claude "$@" ;;
        q|quit) exit 0 ;;
        *) echo 'Enter 1 for Oh My Pi, 2 for Codex, 3 for Claude Code, or q to quit.' >&2 ;;
      esac
    done
  '';
}
