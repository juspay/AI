{ pkgs, lib, opencode, opencode-juspay-editable, opencode-juspay-oneclick, opencode-oneclick }:
pkgs.writeShellApplication {
  name = "opencode";
  runtimeInputs = [ pkgs.gum ];
  text = ''
    if [ "$#" -gt 0 ]; then
      exec ${lib.getExe opencode-juspay-oneclick} "$@"
    fi

    choice=$(gum choose --header "Choose OpenCode variant:" \
      "opencode-juspay-oneclick  — Juspay config and skills bundled" \
      "opencode-oneclick         — Skills bundled, bring your own provider" \
      "opencode-juspay-editable  — Creates editable Juspay config at ~/.config/opencode/" \
      "opencode                  — Plain OpenCode, no config")

    case "$choice" in
      opencode-juspay-oneclick*)  exec ${lib.getExe opencode-juspay-oneclick} ;;
      opencode-oneclick*)         exec ${lib.getExe opencode-oneclick} ;;
      opencode-juspay-editable*)  exec ${lib.getExe opencode-juspay-editable} ;;
      opencode*)                  exec ${lib.getExe opencode} ;;
      *)                          echo "No selection made."; exit 1 ;;
    esac
  '';
}
