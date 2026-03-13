{ pkgs, lib, opencode, configFile }:
let
  initScript = ''
    if [ -z "$JUSPAY_API_KEY" ]; then
      echo "Error: JUSPAY_API_KEY environment variable is not set." >&2
      echo "Please set it before running opencode:" >&2
      echo "  export JUSPAY_API_KEY=your-api-key" >&2
      exit 1
    fi
  '';
in
pkgs.runCommand "opencode-juspay" {
  nativeBuildInputs = [ pkgs.makeWrapper ];
  meta.mainProgram = "opencode";
} ''
  mkdir -p $out/bin
  makeWrapper ${lib.getExe opencode} $out/bin/opencode \
    --run '${initScript}' \
    --set OPENCODE_CONFIG ${configFile}
''
