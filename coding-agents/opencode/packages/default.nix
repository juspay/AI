{ pkgs, lib, opencode, opencode-init, opencode-oneclick }:
pkgs.writeShellApplication {
  name = "opencode";
  runtimeInputs = [ pkgs.gum ];
  text = ''
    choice=$(gum choose --header "Choose OpenCode variant:" \
      "oneclick  — Ready to go with Juspay config and skills bundled" \
      "init      — Creates editable Juspay config at ~/.config/opencode/" \
      "opencode  — Plain OpenCode, no Juspay config")

    case "$choice" in
      oneclick*) exec ${lib.getExe' opencode-oneclick "opencode"} "$@" ;;
      init*)     exec ${lib.getExe' opencode-init "opencode"} "$@" ;;
      opencode*) exec ${lib.getExe' opencode "opencode"} "$@" ;;
      *)         echo "No selection made."; exit 1 ;;
    esac
  '';
}
