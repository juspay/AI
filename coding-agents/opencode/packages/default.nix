{ pkgs, lib, opencode, opencode-juspay-editable, opencode-juspay-oneclick, opencode-oneclick }:
pkgs.writeShellApplication {
  name = "opencode";
  runtimeInputs = [ pkgs.gum ];
  text = ''
    choice=$(gum choose --header "Choose OpenCode variant:" \
      "opencode-juspay-oneclick  — Juspay config and .agents/ bundled" \
      "opencode-oneclick         — .agents/ bundled, bring your own provider" \
      "opencode-juspay-editable  — Creates editable Juspay config at ~/.config/opencode/" \
      "opencode                  — Plain OpenCode, no config")

    case "$choice" in
      opencode-juspay-oneclick*)  exec ${lib.getExe' opencode-juspay-oneclick "opencode"} "$@" ;;
      opencode-oneclick*)         exec ${lib.getExe' opencode-oneclick "opencode"} "$@" ;;
      opencode-juspay-editable*)  exec ${lib.getExe' opencode-juspay-editable "opencode"} "$@" ;;
      opencode*)                  exec ${lib.getExe' opencode "opencode"} "$@" ;;
      *)                          echo "No selection made."; exit 1 ;;
    esac
  '';
}
