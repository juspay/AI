{
  description = "Claude Code standalone package tests";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    oc.url = "github:juspay/oc";
  };

  outputs = { self, nixpkgs, oc }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      checks.${system} = {
        claude-code-oneclick = pkgs.testers.runNixOSTest (import ./test-oneclick.nix { inherit oc; });
        claude-code-juspay-oneclick = pkgs.testers.runNixOSTest (import ./test-juspay-oneclick.nix { inherit oc; });
      };
    };
}
