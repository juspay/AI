{ ... }: {
  programs.opencode = {
    enable = true;
    autoWire.dirs = [ ../../../.agents ];
    settings = import ../settings;
  };
}
