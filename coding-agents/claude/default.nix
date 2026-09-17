# Claude's plugin layout and CLI are local to this adapter. Shared sources stay
# portable; no provider initialization or persistent plugin install is needed.
{ lib, writeShellApplication, runCommand, jq, claude, plugins }:
let
  adaptPlugin = plugin: runCommand "claude-plugin" { nativeBuildInputs = [ jq ]; } ''
    mkdir -p "$out/.claude-plugin" "$out/skills"
    jq '{name, description, homepage, repository, license}
        | with_entries(select(.value != null))' \
      ${plugin}/plugin.json > "$out/.claude-plugin/plugin.json"
    # Materialize assets: Claude rejects component symlinks outside the root.
    cp -rL ${plugin}/skills/. "$out/skills/"
    if [ -f ${plugin}/mcp.json ]; then
      jq '{mcpServers}' ${plugin}/mcp.json > "$out/.mcp.json"
    fi
  '';
  pluginFlags = lib.concatMapStringsSep " "
    (plugin: "--plugin-dir ${lib.escapeShellArg (toString (adaptPlugin plugin))}") plugins;
in
writeShellApplication {
  name = "claude";
  derivationArgs.version = claude.version;
  text = ''
    exec ${lib.getExe claude} ${pluginFlags} "$@"
  '';
}
