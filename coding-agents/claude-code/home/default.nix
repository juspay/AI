{ ... }: {
  programs.claude-code = {
    enable = true;
    autoWire.dirs = [ ../../../.agents ];
  };
}
