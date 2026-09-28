# AI

**Moved.** The Juspay distribution of Oh My Pi, Codex, and Claude Code is now
the `juspay` profile of [agent-distro](https://github.com/juspay/agent-distro):

```bash
AI_PROFILE=juspay nix run github:juspay/agent-distro
AI_PROFILE=juspay AI_HARNESS=omp nix run github:juspay/agent-distro -- --version
```

`nix run github:juspay/AI` and every other output of this flake fail with that
notice. Flakes that used `juspay/AI` as an input should compose
`agent-distro.lib.mkLaunchers` with `agent-distro.profiles.juspay`.

Skills and Kolu are pinned in agent-distro's `profiles/juspay/` and updated
daily there. This repository receives no further updates.
