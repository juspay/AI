# List available targets
default:
    @just --list

# Record the demo screencast (requires LITELLM_API_KEY)
demo:
    nix run ./demo -- demo/demo.tape
    mv demo.gif demo/

# Run the wrapper package tests (NixOS VMs; Linux only)
test:
    nix flake check -L ./test
