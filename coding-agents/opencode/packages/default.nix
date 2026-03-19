{ pkgs, lib, opencode, opencode-juspay-editable, opencode-juspay-oneclick, opencode-oneclick, claude-code, claude-code-oneclick }:
pkgs.writeShellApplication {
  name = "opencode";
  runtimeInputs = [ pkgs.gum ];
  text = ''
    choice=$(gum choose --header "Choose coding agent:" \
      "opencode-juspay-oneclick  — OpenCode: Juspay config and .agents/ bundled" \
      "opencode-oneclick         — OpenCode: .agents/ bundled, bring your own provider" \
      "opencode-juspay-editable  — OpenCode: Creates editable Juspay config at ~/.config/opencode/" \
      "opencode                  — OpenCode: Plain, no config" \
      "claude-code-oneclick      — Claude Code: .agents/ skills bundled" \
      "claude-code               — Claude Code: Plain, no config")

    case "$choice" in
      opencode-juspay-oneclick*)  exec ${lib.getExe' opencode-juspay-oneclick "opencode"} "$@" ;;
      opencode-oneclick*)         exec ${lib.getExe' opencode-oneclick "opencode"} "$@" ;;
      opencode-juspay-editable*)  exec ${lib.getExe' opencode-juspay-editable "opencode"} "$@" ;;
      opencode*)                  exec ${lib.getExe' opencode "opencode"} "$@" ;;
      claude-code-oneclick*)      exec ${lib.getExe' claude-code-oneclick "claude"} "$@" ;;
      claude-code*)               exec ${lib.getExe' claude-code "claude"} "$@" ;;
      *)                          echo "No selection made."; exit 1 ;;
    esac
  '';
}
