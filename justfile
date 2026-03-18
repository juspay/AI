# List available targets
default:
    @just --list

# Record the demo screencast (requires JUSPAY_API_KEY)
demo:
    nix run ./coding-agents/opencode/demo --override-input oc .
    mv demo.gif coding-agents/opencode/demo/
