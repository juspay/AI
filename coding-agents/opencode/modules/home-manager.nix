{ config, lib, pkgs, ... }:
{
  programs.opencode = {
    enable = true;
    settings = import ../juspay/settings.nix;
  };
}
