{ pkgs }:
let
  gumBin = "${pkgs.gum}/bin/gum";
  mktempBin = "${pkgs.coreutils}/bin/mktemp";
  lnBin = "${pkgs.coreutils}/bin/ln";
  jqBin = "${pkgs.jq}/bin/jq";
in
{
  # Ensures JUSPAY_API_KEY is set, prompting interactively if missing.
  # Always runs — we don't bypass based on args, so the user's positional
  # parameters reach pi untouched. Uses ${..:-} for nounset (set -u)
  # compatibility. Same UX as the opencode wrappers.
  ensureApiKey = ''
    if [ -z "''${JUSPAY_API_KEY:-}" ]; then
      cat >&2 <<'MSG'

  JUSPAY_API_KEY is not set.

  Create an API key at: https://grid.ai.juspay.net/dashboard
  (Requires Juspay VPN to access the dashboard)

  Tip: export JUSPAY_API_KEY=... to skip this prompt next time.

MSG
      if [ ! -t 0 ]; then
        echo "Error: cannot prompt for JUSPAY_API_KEY (stdin is not a terminal)." >&2
        exit 1
      fi
      JUSPAY_API_KEY=$(${gumBin} input --password --prompt "JUSPAY_API_KEY: ") || {
        echo "Error: failed to read JUSPAY_API_KEY." >&2
        exit 1
      }
      if [ -z "$JUSPAY_API_KEY" ]; then
        echo "Error: no API key provided." >&2
        exit 1
      fi
      export JUSPAY_API_KEY
    fi
  '';

  # Sets up PI_CODING_AGENT_DIR as a writable per-run temp directory
  # containing a symlink to the given models.json. pi also stores sessions
  # and settings under PI_CODING_AGENT_DIR, so a temp dir additionally keeps
  # pi's state off of ~/.pi — handy for throwaway sandboxes.
  setupAgentDir = { modelsFile }: ''
    PI_CODING_AGENT_DIR=$(${mktempBin} -d -t pi-agent-XXXXXX)
    ln -s ${modelsFile} "$PI_CODING_AGENT_DIR/models.json"
    export PI_CODING_AGENT_DIR
  '';

  # Writes an editable ${modelsFile} to $config_path if the user has no
  # models.json there or in legacy ~/.pi/models.json yet (pi reads ~/.pi/
  # when PI_CODING_AGENT_DIR is unset).
  mkInitScript = { modelsFile, config_path }: ''
    if [ ! -f "${config_path}" ] && [ ! -f "$HOME/.pi/models.json" ]; then
      mkdir -p "$(${pkgs.coreutils}/bin/dirname "${config_path}")"
      cp ${modelsFile} "${config_path}"
      chmod u+w "${config_path}"
    fi
  '';

  # Registers the providers in ${modelsFile} in pi's *existing* agent dir,
  # so the same `pi` invocation works against the gateway without
  # PI_CODING_AGENT_DIR being set (pi merges models.json over its built-in
  # catalog). Idempotent per provider; anything the user already configured
  # under the same provider id is overwritten with our version.
  #
  # Writes through a temp file + mv for atomicity; if jq is not on PATH we
  # fall back to the nix-provided jq.
  addProvidersToDir = { modelsFile, dir_var, jq ? "${jqBin}" }: ''
    _pi_dir="''${${dir_var}:-$HOME/.pi}"
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
  '';
}
