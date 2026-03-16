# List available targets
default:
    @just --list

# Record the demo screencast (requires JUSPAY_API_KEY)
demo:
    cd doc/demo && nix run --override-input oc ../..
