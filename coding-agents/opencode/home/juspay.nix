{ ... }: {
  imports = [ ./default.nix ];
  programs.opencode.settings = {
    model = "litellm/glm-latest";
    agent.explore = { mode = "subagent"; model = "litellm/open-fast"; };
    provider.litellm = import ../juspay/default.nix;
  };
}
