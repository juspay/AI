{ config, lib, pkgs, ... }:
let
  juspayProvider = import ./juspay;
  opencodePkg = pkgs.opencode;
  wrapperScript = pkgs.writeShellScriptBin "opencode" ''
    if [ -z "$JUSPAY_API_KEY" ]; then
      echo "Error: JUSPAY_API_KEY environment variable is not set."
      echo "Please set it before running opencode:"
      echo "  export JUSPAY_API_KEY=your-api-key"
      echo ""
      echo "Or add it to your shell profile for persistence."
      exit 1
    fi
    exec ${lib.getExe opencodePkg} "$@"
  '';
in
{
  programs.opencode = {
    enable = true;
    package = wrapperScript;
    settings = {
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
    };
  };
}
