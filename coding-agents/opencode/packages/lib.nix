let
  # Checks for JUSPAY_API_KEY, skipping for --version/--help.
  # Uses ${..:-} for nounset (set -u) compatibility.
  checkApiKey = ''
    case " $* " in
      *" --version "* | *" --help "* | *" -v "* | *" -h "*) ;;
      *)
        if [ -z "''${JUSPAY_API_KEY:-}" ]; then
          cat >&2 <<'ERR'

      Error: JUSPAY_API_KEY environment variable is not set.

      Create an API key at: https://grid.ai.juspay.net/dashboard
      (Requires Juspay VPN to access the dashboard)

      Then run:
        export JUSPAY_API_KEY=your-api-key

    ERR
          exit 1
        fi
        ;;
    esac
  '';
in
{
  inherit checkApiKey;

  mkInitScript = configFile: ''
    ${checkApiKey}
    config_dir="$HOME/.config/opencode"
    config_file="$config_dir/opencode.json"
    if [ ! -f "$config_file" ]; then
      mkdir -p "$config_dir"
      cp ${configFile} "$config_file"
      chmod u+w "$config_file"
    fi
  '';

  mkConfigDir = { pkgs, configFile, skillsSrc }:
    pkgs.runCommand "opencode-config-dir" { } ''
      mkdir -p $out
      ln -s ${configFile} $out/opencode.json
      ln -s ${skillsSrc}/skills $out/skills
    '';
}
