{ pkgs, lib, opencode, configFile }:
let
  wrapper = import ../../wrapper.nix { inherit pkgs; };
in
pkgs.writeShellApplication {
  name = "opencode";
  text = ''
    ${wrapper.ensureApiKey { }}
    # Seed the config on the first run only. opencode rewrites its settings, so
    # this has to be a writable copy rather than a symlink into the store.
    config_dir="$HOME/.config/opencode"
    if [ ! -e "$config_dir/opencode.json" ]; then
      mkdir -p "$config_dir"
      cp ${configFile} "$config_dir/opencode.json"
      chmod u+w "$config_dir/opencode.json"
    fi
    exec ${lib.getExe opencode} "$@"
  '';
}
