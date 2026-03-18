{ lib, ... }: {
  programs.opencode = {
    enable = true;
    autoWire.dirs = [ ../../../.agents ];
    settings = {
      autoupdate = lib.mkDefault true;
      mcp.deepwiki = lib.mkDefault {
        type = "remote";
        url = "https://mcp.deepwiki.com/mcp";
        enabled = true;
      };
      plugin = lib.mkDefault [ ];
    };
  };
}
