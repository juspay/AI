# Shell bootstrap shared by every agent wrapper in this repo: the Juspay key
# prompt, the throwaway per-run config directory the *-oneclick variants hand
# their agent, and the seed-a-writable-config step the *-editable variants
# perform. Each helper renders a shell fragment; what is agent-specific — which
# files the agent reads, which env var points at its config root — stays at the
# call sites.
{ pkgs }:
let
  inherit (pkgs) lib;
  catalog = import ./catalog.nix;
  apiKeyEnv = catalog.apiKeyEnv;
  # The shell word that expands to the key, for the places the shell itself has
  # to do the expanding (`$JUSPAY_API_KEY`).
  apiKeyRef = "$" + apiKeyEnv;
  gumBin = "${pkgs.gum}/bin/gum";
  mktempBin = "${pkgs.coreutils}/bin/mktemp";
  lnBin = "${pkgs.coreutils}/bin/ln";
in
{
  # Ensures the gateway key is set, prompting interactively if missing. Always
  # runs — we don't bypass based on args, so the user's positional parameters
  # reach the agent untouched (the prior `case " $* "` bypass also incorrectly
  # matched substrings like " -v " inside messages). Uses ${..:-} for nounset
  # (set -u) compatibility.
  ensureApiKey = ''
    if [ -z "''${${apiKeyEnv}:-}" ]; then
      cat >&2 <<'MSG'

  ${apiKeyEnv} is not set.

  Create an API key at: ${catalog.apiKeyUrl}
  (Requires Juspay VPN to access the dashboard)

  Tip: export ${apiKeyEnv}=... to skip this prompt next time.

MSG
      if [ ! -t 0 ]; then
        echo "Error: cannot prompt for ${apiKeyEnv} (stdin is not a terminal)." >&2
        exit 1
      fi
      ${apiKeyEnv}=$(${gumBin} input --password --prompt "${apiKeyEnv}: ") || {
        echo "Error: failed to read ${apiKeyEnv}." >&2
        exit 1
      }
      if [ -z "${apiKeyRef}" ]; then
        echo "Error: no API key provided." >&2
        exit 1
      fi
      export ${apiKeyEnv}
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

  # Seed a writable config file the first time an *-editable variant runs:
  # create the directory, copy the generated file in, make it writable. Skipped
  # once the user has a config of their own — `existing` lists every path that
  # counts as one (agents that also read a legacy filename list it too).
  seedConfigFile = { src, dir, name, existing ? [ "${dir}/${name}" ] }:
    lib.concatStringsSep "\n" [
      "if ${lib.concatMapStringsSep " && " (path: "[ ! -e \"${path}\" ]") existing}; then"
      "mkdir -p \"${dir}\""
      "cp ${src} \"${dir}/${name}\""
      "chmod u+w \"${dir}/${name}\""
      "fi"
    ];
}
