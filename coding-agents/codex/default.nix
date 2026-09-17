# Codex owns marketplace registration, installation, and its persistent state.
# Portable plugin contents and provider policy stay outside this adapter.
{ lib, writeShellApplication, runCommand, jq, codex, plugins }:
let
  marketplace = runCommand "codex-juspay-ai-marketplace" { nativeBuildInputs = [ jq ]; } ''
    mkdir -p "$out/.agents/plugins"
    for plugin in ${lib.escapeShellArgs (map toString plugins)}; do
      name=$(jq -er '.name' "$plugin/plugin.json")
      ln -s "$plugin" "$out/$name"
      jq -n --arg name "$name" '{
        name: $name,
        source: {source: "local", path: ("./" + $name)},
        policy: {installation: "AVAILABLE", authentication: "ON_INSTALL"},
        category: "Productivity"
      }' >> entries.json
      printf '%s\n' "$name@juspay-ai" >> "$out/plugin-ids"
    done
    jq -s '{name: "juspay-ai", plugins: .}' entries.json > "$out/.agents/plugins/marketplace.json"
  '';
in
writeShellApplication {
  name = "codex";
  derivationArgs.version = codex.version;
  text = ''
    # Use the native installer rather than writing Codex's cache layout. Install
    # on every launch: portable sources need not bump a manifest version when
    # their flake input changes. Codex preserves unrelated config and auth.
    ${lib.getExe codex} plugin marketplace add ${marketplace} >/dev/null
    while IFS= read -r plugin; do
      ${lib.getExe codex} plugin add "$plugin" >/dev/null
    done < ${marketplace}/plugin-ids
    exec ${lib.getExe codex} "$@"
  '';
}
