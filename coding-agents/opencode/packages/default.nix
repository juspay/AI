{ pkgs, lib, opencode, opencode-juspay-editable, opencode-juspay-oneclick, opencode-oneclick, claude-code, claude-code-oneclick, claude-code-juspay-oneclick }:
pkgs.writeShellApplication {
  name = "opencode";
  runtimeInputs = [ pkgs.gum ];
  text = ''
    agent=$(gum choose --header "Choose coding agent:" \
      "OpenCode" \
      "Claude Code")

    case "$agent" in
      "OpenCode")
        variant=$(gum choose --header "Choose OpenCode variant:" \
          "juspay-oneclick  — Juspay config and .agents/ bundled" \
          "oneclick         — .agents/ bundled, bring your own provider" \
          "juspay-editable  — Creates editable Juspay config at ~/.config/opencode/" \
          "plain            — No config")
        case "$variant" in
          juspay-oneclick*)  exec ${lib.getExe' opencode-juspay-oneclick "opencode"} "$@" ;;
          oneclick*)         exec ${lib.getExe' opencode-oneclick "opencode"} "$@" ;;
          juspay-editable*)  exec ${lib.getExe' opencode-juspay-editable "opencode"} "$@" ;;
          plain*)            exec ${lib.getExe' opencode "opencode"} "$@" ;;
          *)                 echo "No selection made."; exit 1 ;;
        esac
        ;;
      "Claude Code")
        variant=$(gum choose --header "Choose Claude Code variant:" \
          "juspay-oneclick  — Juspay provider and .agents/ skills bundled" \
          "oneclick         — .agents/ skills bundled, bring your own provider" \
          "plain            — No config")
        case "$variant" in
          juspay-oneclick*)  exec ${lib.getExe' claude-code-juspay-oneclick "claude"} "$@" ;;
          oneclick*)         exec ${lib.getExe' claude-code-oneclick "claude"} "$@" ;;
          plain*)            exec ${lib.getExe' claude-code "claude"} "$@" ;;
          *)                 echo "No selection made."; exit 1 ;;
        esac
        ;;
      *)
        echo "No selection made."; exit 1 ;;
    esac
  '';
}
