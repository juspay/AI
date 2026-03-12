# AGENTS.md

When making changes to this flake, quickly verify the build works:

```bash
nix run . -- --version
```

This should print the opencode version.

To run CI locally (including the home-manager example test):

```bash
vira ci -b
```
