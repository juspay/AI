{ sources }:
{
  name = "kolu";
  description = "Kolu skill and MCP server with your own provider";
  plugins = [ "${sources.kolu}/agent-plugin" ];
  gateway = null;
}
