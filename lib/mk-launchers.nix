# Bind upstream binaries once; consumers supply their package set and profile.
{ oh-my-pi, codex-cli, claude-code }:
{ pkgs, profile }:
let
  system = pkgs.stdenv.hostPlatform.system;
  inherit (profile) plugins;
  gateway = profile.gateway or null;
  omp = pkgs.callPackage ../coding-agents/omp {
    inherit plugins gateway;
    omp = oh-my-pi.packages.${system}.default;
  };
  codex = pkgs.callPackage ../coding-agents/codex {
    inherit plugins;
    marketplaceName = "${profile.name}-ai";
    codex = codex-cli.packages.${system}.default;
  };
  claude = pkgs.callPackage ../coding-agents/claude {
    inherit plugins;
    claude = claude-code.packages.${system}.default;
  };
in
{
  inherit omp codex claude;
  picker = pkgs.callPackage ../coding-agents/picker.nix {
    inherit omp codex claude profile;
  };
}
