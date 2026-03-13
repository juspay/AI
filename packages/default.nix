{ pkgs, lib, opencode, configFile }:
let
  initScript = ''
    config_dir="$HOME/.config/opencode"
    config_file="$config_dir/opencode.json"
    if [ ! -f "$config_file" ]; then
      mkdir -p "$config_dir"
      cp ${configFile} "$config_file"
      chmod u+w "$config_file"
    fi
  '';
in
opencode.overrideAttrs (old: {
  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
  postFixup = ''
    wrapProgram $out/bin/opencode --run '${initScript}'
  '';
})
