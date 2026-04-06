{ pkgs, lib, opencode, opencode-juspay-editable, opencode-juspay-oneclick, opencode-oneclick, claude-code-juspay-oneclick }:
pkgs.writeShellApplication {
  name = "opencode";
  runtimeInputs = [ pkgs.gum ];
  text = ''
    choice=$(gum choose --header "Choose a coding agent:" \
      "claude-code-juspay-oneclick — Claude Code with Juspay config and skills" \
      "opencode-juspay-oneclick    — OpenCode with Juspay config and skills" \
      "opencode-oneclick           — OpenCode with skills, bring your own provider" \
      "opencode-juspay-editable    — OpenCode with editable Juspay config at ~/.config/opencode/" \
      "opencode                    — Plain OpenCode, no config")

    case "$choice" in
      claude-code-juspay-oneclick*) exec ${lib.getExe claude-code-juspay-oneclick} "$@" ;;
      opencode-juspay-oneclick*)    exec ${lib.getExe opencode-juspay-oneclick} "$@" ;;
      opencode-oneclick*)           exec ${lib.getExe opencode-oneclick} "$@" ;;
      opencode-juspay-editable*)    exec ${lib.getExe opencode-juspay-editable} "$@" ;;
      opencode*)                    exec ${lib.getExe opencode} "$@" ;;
      *)                            echo "No selection made."; exit 1 ;;
    esac
  '';
}
