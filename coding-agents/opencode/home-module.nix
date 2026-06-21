# Home Manager module: install the opencode *configuration* (not the binary).
#
# Renders the same opencode.json as
# `coding-agents/opencode/packages/config.nix` and places it at
# `$XDG_CONFIG_HOME/opencode/opencode.json`. The opencode package itself is
# intentionally NOT installed — bring your own binary. Use this when you want
# Juspay's opencode config (the litellm gateway + model catalog) layered onto
# an opencode you manage elsewhere.
#
# Usage (flake-based home-manager):
#
#   # flake inputs:
#   juspay-ai.url = "github:juspay/AI";
#
#   # home configuration:
#   imports = [ inputs.juspay-ai.homeModules.opencode ];
#   programs.opencode-juspay.enable = true;
#
# The Juspay provider expects JUSPAY_API_KEY in the environment at runtime
# (create one at https://grid.ai.juspay.net/dashboard, requires Juspay VPN).
{ config, lib, pkgs, ... }:
let
  cfg = config.programs.opencode-juspay;
  inherit (lib) mkEnableOption mkOption mkIf types optionalAttrs;

  baseSettings = import ./settings;
  juspaySettings = import ./settings/juspay.nix;

  settings =
    baseSettings
    // optionalAttrs cfg.juspay juspaySettings
    // cfg.settings;

  # Reuse the canonical renderer so the module and the packaged variants
  # cannot drift apart.
  configFile = import ./packages/config.nix { inherit pkgs settings; };
in
{
  options.programs.opencode-juspay = {
    enable = mkEnableOption "the Juspay opencode configuration (config only, no package)";

    juspay = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Include the Juspay provider/model settings — the litellm gateway at
        grid.ai.juspay.net, which expects JUSPAY_API_KEY at runtime. Set to
        false to install only the upstream base settings.
      '';
    };

    settings = mkOption {
      type = types.attrs;
      default = { };
      example = lib.literalExpression ''{ theme = "tokyonight"; }'';
      description = ''
        Extra opencode settings merged on top of the base (and, when
        {option}`programs.opencode-juspay.juspay` is enabled, Juspay) settings.
      '';
    };
  };

  config = mkIf cfg.enable {
    xdg.configFile."opencode/opencode.json".source = configFile;
  };
}
