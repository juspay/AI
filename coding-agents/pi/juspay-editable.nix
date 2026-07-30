{ pkgs, lib, pi, modelsFile }:
let
  piLib = import ./lib.nix { inherit pkgs; };
in
pkgs.writeShellApplication {
  name = "pi";
  text = ''
    ${piLib.ensureApiKey}
    # Merge the Juspay providers into the user's existing models.json (pi
    # merges that file over its built-in catalog), keeping their own
    # providers, sessions and settings untouched.
    ${piLib.addProvidersToDir { inherit modelsFile; dir_var = "PI_CODING_AGENT_DIR"; }}
    exec ${lib.getExe pi} "$@"
  '';
}
