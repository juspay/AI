# Codex owns marketplace registration, installation, and its persistent state.
# Portable plugin contents and provider policy stay outside this adapter.
{ lib, writeShellApplication, runCommand, jq, codex, plugins, marketplaceName }:
let
  marketplace = runCommand "codex-${marketplaceName}-marketplace" { nativeBuildInputs = [ jq ]; } ''
    mkdir -p "$out/.agents/plugins"
    touch entries.json "$out/plugin-ids"
    for plugin in ${lib.escapeShellArgs (map toString plugins)}; do
      name=$(jq -er '.name' "$plugin/plugin.json")
      ln -s "$plugin" "$out/$name"
      jq -n --arg name "$name" '{
        name: $name,
        source: {source: "local", path: ("./" + $name)},
        policy: {installation: "AVAILABLE", authentication: "ON_INSTALL"},
        category: "Productivity"
      }' >> entries.json
      printf '%s\n' "$name@${marketplaceName}" >> "$out/plugin-ids"
    done
    jq -s --arg name ${lib.escapeShellArg marketplaceName} '{name: $name, plugins: .}' entries.json > "$out/.agents/plugins/marketplace.json"
  '';
in
writeShellApplication {
  name = "codex";
  runtimeInputs = [ jq ];
  derivationArgs.version = codex.version;
  text = lib.optionalString (plugins != [ ]) ''
    # The name stays fixed, but its store path changes between builds. Use the
    # native installer only when that path changes, preserving disabled plugins
    # on steady-state launches as well as unrelated config and auth.
    marketplace=${marketplace}
    registered=$(${lib.getExe codex} plugin marketplace list --json \
      | jq -r --arg n ${lib.escapeShellArg marketplaceName} '.marketplaces[] | select(.name == $n) | .root')
    if [ "$registered" != "$marketplace" ]; then
      if [ -n "$registered" ]; then
        ${lib.getExe codex} plugin marketplace remove ${lib.escapeShellArg marketplaceName} >/dev/null
      fi
      ${lib.getExe codex} plugin marketplace add "$marketplace" >/dev/null
      while IFS= read -r plugin; do
        ${lib.getExe codex} plugin add "$plugin" >/dev/null
      done < "$marketplace/plugin-ids"
    fi
  '' + ''
    exec ${lib.getExe codex} "$@"
  '';
}
