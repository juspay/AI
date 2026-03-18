let
  juspayProvider = import ./default.nix;
in
{
  model = "litellm/glm-latest";
  agent = {
    explore = {
      mode = "subagent";
      model = "litellm/open-fast";
    };
  };
  autoupdate = true;
  provider = {
    litellm = juspayProvider;
  };
  mcp = {
    deepwiki = {
      type = "remote";
      url = "https://mcp.deepwiki.com/mcp";
      enabled = true;
    };
  };
  plugin = [ ];
}
