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
opencode.overrideAttrs (old: {
  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
  postFixup = ''
    wrapProgram $out/bin/opencode --run '${initScript}' --set OPENCODE_CONFIG ${configFile}
  '';
})
