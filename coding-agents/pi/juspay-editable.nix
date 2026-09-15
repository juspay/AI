{ pkgs, lib, pi, modelsFile }:
let
  wrapper = import ../wrapper.nix { inherit pkgs; };
  mktempBin = "${pkgs.coreutils}/bin/mktemp";
  jqBin = "${pkgs.jq}/bin/jq";
in
pkgs.writeShellApplication {
  name = "pi";
  text = ''
    ${wrapper.ensureApiKey}
    # Merge the Juspay providers into the user's existing models.json (pi merges
    # that file over its built-in catalog), keeping their own providers, sessions
    # and settings untouched. Idempotent per provider; anything the user already
    # configured under the same provider id is overwritten with our version.
    # Writes through a temp file + mv for atomicity.
    _pi_dir="''${PI_CODING_AGENT_DIR:-$HOME/.pi}"
    mkdir -p "$_pi_dir"
    _pi_models="$_pi_dir/models.json"
    if [ ! -f "$_pi_models" ]; then
      printf '{ "providers": {} }\n' > "$_pi_models"
      chmod u+w "$_pi_models"
    fi
    _pi_tmp="$(${mktempBin} -t pi-models-XXXXXX)"
    ${jqBin} -s '.[0].providers = (.[0].providers // {}) + .[1].providers | .[0]' \
      "$_pi_models" ${modelsFile} > "$_pi_tmp"
    mv "$_pi_tmp" "$_pi_models"
    unset _pi_dir _pi_models _pi_tmp
    exec ${lib.getExe pi} "$@"
  '';
}
