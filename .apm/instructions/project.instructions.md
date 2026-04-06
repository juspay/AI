---
description: Project-specific build verification and CI instructions
---

When making changes to this flake, quickly verify the build works:

```bash
nix run . -- --version
```

This should print the opencode version.

To run CI locally:

```bash
vira ci -b
```
