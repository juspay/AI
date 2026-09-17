# Oh My Pi

## Juspay gateway

```bash
nix run github:juspay/AI#juspay.omp
```

Create a gateway key at [grid.ai.juspay.net/dashboard](https://grid.ai.juspay.net/dashboard)
(Juspay employees only). Creating the key requires VPN; using it afterwards does
not. Export `LITELLM_API_KEY` to skip the launcher's key prompt on subsequent runs.

## Your own provider

Use `nix run github:juspay/AI#vanilla.omp` for OMP without plugins or a gateway.
To keep the Juspay profile’s plugins while disabling its gateway:

```bash
AI_GATEWAY=0 nix run github:juspay/AI#juspay.omp
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

[`coding-agents/omp/default.nix`](../coding-agents/omp/default.nix) builds one
launcher using the selected profile’s plugins and optional `gateway` attrset.
Gateway initialization is guarded by `AI_GATEWAY != 0`. With the Juspay
profile, the wrapper:

1. **Ensures the gateway key**, prompting for `LITELLM_API_KEY` if it is unset.
2. **Points omp at the gateway** with `LITELLM_BASE_URL`. OMP ships LiteLLM
   discovery, so this flake vendors **no model list at all**: omp asks the
   gateway what it serves — ids, context windows, capabilities — at startup.
   What the model picker shows is what your key can actually call, with the
   limits the gateway enforces.
3. **Loads two extension roots** on omp's own command line — the store-built
   juspay/skills input (`-e /nix/store/…-source`) and kolu's own
   agent plugin (`-e /nix/store/…/agent-plugin`). CLI extension roots are added
   to whatever `extensions:` your settings already list, so these and your own
   extensions compose.
4. **Fills missing model roles and settings on every launch.** In
   `~/.omp/agent/config.yml`, absent `default` / `task` / `slow` roles get
   `litellm/open-large`, and an absent `smol` role gets `litellm/open-fast`. This
   also repairs older configs so workers and reviewers have explicit defaults
   independent of the primary. `task.showResolvedModelBadge` is switched on the
   same way, so task rows name the model each subagent actually resolved to
   instead of hiding it.

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

The `omp` binary itself is **upstream's own build**: this flake takes it from
[upstream's flake](https://github.com/can1357/oh-my-pi/blob/main/flake.nix) pinned
to a release tag, and adds only the wrapper above and the skills plugin. If you
would rather manage OMP declaratively, upstream also ships `programs.omp` Home
Manager and NixOS modules — this flake does not use them, and the package here is
a wrapper, not a module.
