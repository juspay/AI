# Shell bootstrap shared by every agent wrapper in this repo: the Juspay key
# prompt and the throwaway per-run config directory the *-oneclick variants hand
# their agent. Each helper renders a shell fragment; what is agent-specific —
# which files the agent reads, which env var points at its config root, which
# name the agent expects the key under — stays at the call sites.
{ pkgs }:
let
  inherit (pkgs) lib;
  catalog = import ./catalog.nix;
  gumBin = "${pkgs.gum}/bin/gum";
  mktempBin = "${pkgs.coreutils}/bin/mktemp";
  lnBin = "${pkgs.coreutils}/bin/ln";
in
{
  # Ensures the gateway key is set, prompting interactively if missing. `env` is
  # the name the calling agent expects it under: the catalog's by default, the
  # agent's own convention where it has one (OMP reads LiteLLM keys as
  # LITELLM_API_KEY). Always runs — we don't bypass based on args, so the user's
  # positional parameters reach the agent untouched (the prior `case " $* "`
  # bypass also incorrectly matched substrings like " -v " inside messages).
  # The `:-` keeps it compatible with nounset (set -u).
  ensureApiKey = { env ? catalog.apiKeyEnv }:
    let
      # The shell word that expands to that variable, for the one place the
      # shell itself has to do the expanding.
      ref = "$" + env;
    in
    ''
      if [ -z "''${${env}:-}" ]; then
        cat >&2 <<'MSG'

  ${env} is not set.

  Create an API key at: ${catalog.apiKeyUrl}
  (Requires Juspay VPN to access the dashboard)

  Tip: export ${env}=... to skip this prompt next time.

MSG
        if [ ! -t 0 ]; then
          echo "Error: cannot prompt for ${env} (stdin is not a terminal)." >&2
          exit 1
        fi
        ${env}=$(${gumBin} input --password --prompt "${env}: ") || {
          echo "Error: failed to read ${env}." >&2
          exit 1
        }
        if [ -z "${ref}" ]; then
          echo "Error: no API key provided." >&2
          exit 1
        fi
        export ${env}
      fi
    '';

  # Give the agent a writable per-run directory holding the generated config it
  # should read, and point its own env var at it (`links` are symlinked; files
  # the agent rewrites itself belong in `copies`, which are made writable). The
  # directory cannot live in the store: the agent writes into it (opencode drops
  # a .gitignore there).
  mkTempAgentDir = { envVar, prefix, links ? { }, copies ? { } }:
    lib.concatStringsSep "\n" (
      [
        "${envVar}=$(${mktempBin} -d -t ${prefix}-XXXXXX)"
        "export ${envVar}"
      ]
      ++ map (name: "${lnBin} -s ${links.${name}} \"\$${envVar}/${name}\"") (lib.attrNames links)
      ++ lib.concatMap (name: [
        "cp ${copies.${name}} \"\$${envVar}/${name}\""
        "chmod u+w \"\$${envVar}/${name}\""
      ]) (lib.attrNames copies)
    );
}
