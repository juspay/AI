mod agent

# List available targets
default:
    @just --list

# Record the demo screencast (requires JUSPAY_API_KEY)
demo:
    nix run ./demo --override-input ai . -- coding-agents/opencode/demo.tape
    mv demo.gif demo/

# Run the wrapper package tests (NixOS VMs; Linux only)
test:
    nix flake check -L ./coding-agents/test/standalone --override-input ai .

# Refresh the gateway model snapshot opencode reads (needs the gateway API key).
# The gateway and key name come from coding-agents/catalog.nix, so the recipe
# and the snapshot cannot disagree about them.
refresh-gateway-models:
    python3 coding-agents/refresh-gateway-models.py \
      --gateway "$(nix eval --raw --file coding-agents/catalog.nix --apply 'c: c.gatewayUrl')" \
      --key-env "$(nix eval --raw --file coding-agents/catalog.nix --apply 'c: c.apiKeyEnv')"
