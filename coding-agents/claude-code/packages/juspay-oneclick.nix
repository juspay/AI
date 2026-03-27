{ pkgs, lib, claude-code, skillsSrc }:
let
  ccLib = import ./lib.nix;
  juspaySettings = import ../settings/juspay.nix;
  # Build makeWrapper --set-default flags from the static env vars
  envFlags = lib.concatStringsSep " \\\n    "
    (lib.mapAttrsToList (k: v: "--set-default ${k} ${lib.escapeShellArg v}") juspaySettings.env);
in
pkgs.runCommand "claude-code-juspay-oneclick" {
  nativeBuildInputs = [ pkgs.makeWrapper ];
  meta.mainProgram = "claude";
} ''
  mkdir -p $out/bin
  makeWrapper ${lib.getExe claude-code} $out/bin/claude \
    --run 'export CLAUDE_CODE_WRAPPER_ARGS="$@"' \
    --run '${ccLib.checkApiKey}' \
    --run 'export ANTHROPIC_AUTH_TOKEN="$JUSPAY_API_KEY"' \
    --run '${ccLib.mkSkillsInitScript skillsSrc}' \
    ${envFlags}
''
