rec {
  # Shared init script snippet that checks for JUSPAY_API_KEY.
  # Skips the check when --version or --help is passed.
  checkApiKey = ''
    case " $OPENCODE_WRAPPER_ARGS " in
      *" --version "* | *" --help "* | *" -v "* | *" -h "*) ;;
      *)
        if [ -z "$JUSPAY_API_KEY" ]; then
          echo "" >&2
          echo "  Error: JUSPAY_API_KEY environment variable is not set." >&2
          echo "" >&2
          echo "  Create an API key at: https://grid.ai.juspay.net/dashboard" >&2
          echo "  (Requires Juspay VPN to access the dashboard)" >&2
          echo "" >&2
          echo "  Then run:" >&2
          echo "    export JUSPAY_API_KEY=your-api-key" >&2
          echo "" >&2
          exit 1
        fi
        ;;
    esac
  '';

  # Init script that checks for JUSPAY_API_KEY and copies the config file.
  # Takes configFile as an argument (the Nix store path to the config).
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
}

