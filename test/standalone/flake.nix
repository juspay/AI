{
  description = "OpenCode default package test";

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
        default = pkgs.testers.runNixOSTest (import ./test.nix { inherit oc; });
        oneclick = pkgs.testers.runNixOSTest (import ./test-oneclick.nix { inherit oc; });
      };
    };
}
