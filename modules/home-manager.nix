{ config, lib, pkgs, ... }:
let
  opencodeJuspay = import ./juspay/package.nix { inherit pkgs lib; };
in
{
  programs.opencode = {
    enable = true;
    package = opencodeJuspay;
    settings = import ./juspay/settings.nix;
  };
}
