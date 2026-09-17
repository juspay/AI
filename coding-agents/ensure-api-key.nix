# Shell fragment: acquire the shared gateway credential in the caller's
# environment. Each agent adapter maps it to its own authentication interface.
{ gum, gateway }:
''
  if [ -z "''${LITELLM_API_KEY:-}" ]; then
    cat >&2 <<'MSG'

  LITELLM_API_KEY is not set.

  Create an API key at: ${gateway.url}/dashboard
  (Requires Juspay VPN to access the dashboard)

  Tip: export LITELLM_API_KEY=... to skip this prompt next time.

  MSG
    if [ ! -t 0 ]; then
      echo "Error: cannot prompt for LITELLM_API_KEY (stdin is not a terminal)." >&2
      exit 1
    fi
    LITELLM_API_KEY=$(${gum}/bin/gum input --password --prompt "LITELLM_API_KEY: ") || {
      echo "Error: failed to read LITELLM_API_KEY." >&2
      exit 1
    }
    if [ -z "$LITELLM_API_KEY" ]; then
      echo "Error: no API key provided." >&2
      exit 1
    fi
    export LITELLM_API_KEY
  fi
''
