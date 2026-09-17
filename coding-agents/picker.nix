# Selection only: each launcher owns its initialization and plugin protocol.
{ lib, writeShellApplication, omp, codex, claude }:
writeShellApplication {
  name = "ai";
  text = ''
    if [ ! -t 0 ]; then
      echo 'Choose an agent with nix run github:juspay/AI#omp, github:juspay/AI#codex, or github:juspay/AI#claude.' >&2
      exit 1
    fi

    printf 'Choose a coding agent:\n  1) Oh My Pi\n  2) Codex\n  3) Claude Code\n' >&2
    while true; do
      printf 'Agent [1/2/3] (q to quit): ' >&2
      read -r choice
      case "$choice" in
        1|omp) exec ${lib.getExe omp} "$@" ;;
        2|codex) exec ${lib.getExe codex} "$@" ;;
        3|claude) exec ${lib.getExe claude} "$@" ;;
        q|quit) exit 0 ;;
        *) echo 'Enter 1 for Oh My Pi, 2 for Codex, 3 for Claude Code, or q to quit.' >&2 ;;
      esac
    done
  '';
}
