# List available targets
default:
    @just --list

# Record the demo screencast (requires JUSPAY_API_KEY)
demo:
    nix run ./demo --override-input oc . -- coding-agents/opencode/demo.tape
    mv demo.gif demo/
