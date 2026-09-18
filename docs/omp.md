# Oh My Pi

## Juspay gateway

```bash
nix run github:juspay/AI#omp
```

Create a gateway key at [grid.ai.juspay.net/dashboard](https://grid.ai.juspay.net/dashboard)
(Juspay employees only). Creating the key requires VPN; using it afterwards does
not. Export `LITELLM_API_KEY` to skip the launcher's key prompt on subsequent runs.

## Your own provider

Use `nix run github:juspay/agent-distro#omp` for OMP without plugins or a gateway.
To keep the Juspay profile’s plugins while disabling its gateway:

```bash
AI_GATEWAY=0 nix run github:juspay/AI#omp
```

This is the **same package**, with Juspay integration disabled for that launch.
Skills and the Kolu plugin still load, but the wrapper skips the gateway key
prompt, LiteLLM environment injection, model-role defaults, and onboarding bypass.
On a fresh setup, OMP walks you through connecting your own provider.

`AI_GATEWAY` is a runtime switch: only `0` disables integration; unset or any other
value keeps the default behavior. No Nix `--impure` flag or rebuild is needed.

Opting out does **not** erase existing settings, credentials, or environment
variables. If you previously used the gateway, select your own models with
`/model` and connect your provider with `omp setup`, or set
`PI_CODING_AGENT_DIR` to a separate directory for independent state.

## Gateway initialization

The [agent-distro adapters](https://github.com/juspay/agent-distro#readme)
implement gateway initialization from this repo's [`profile.nix`](../profile.nix).
With the gateway enabled, OMP uses `https://grid.ai.juspay.net` and your
`LITELLM_API_KEY`, discovering available models and their limits at runtime.
No model catalog is vendored here.

On launch, missing `default`, `task`, and `slow` model roles receive
`litellm/open-large`; an absent `smol` role receives `litellm/open-fast`.
The launcher also defaults `task.showResolvedModelBadge` to true, so task rows
show the model each subagent resolved to. Both Juspay skills and Kolu load
alongside your own extensions.

That config file is **yours** — the ordinary settings file `/model` and
`/settings` write to. Existing role assignments, unrelated settings, and YAML
comments are preserved. When everything the wrapper defaults is already present,
the file is not rewritten. Sessions, auth and onboarding state persist across
runs. Removing a role makes it receive the wrapper default on the next launch;
edit its value to choose a custom model, and turn the badge back off in
`/settings` if you would rather not see it. Invalid YAML is reported without
modifying the file.

(If you export `PI_CODING_AGENT_DIR`, the wrapper fills defaults there instead.)

If you run upstream OMP yourself rather than through this wrapper, these two
variables are all it needs to use the gateway:

```bash
export LITELLM_BASE_URL=https://grid.ai.juspay.net
export LITELLM_API_KEY=...   # the gateway key
omp
```

Everything else is ordinary omp: `--model litellm/kimi-k3` to start elsewhere,
`ctrl+p` to cycle role models, `/switch` to change provider.

The `omp` binary is upstream's own build, pinned to a release tag by
[agent-distro](https://github.com/juspay/agent-distro#readme). That repository
owns packaging and adapter mechanisms; this distribution owns the Juspay
profile and follows its framework pin.
