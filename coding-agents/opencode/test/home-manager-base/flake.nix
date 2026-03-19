{
  description = "OpenCode home-manager base module test (no Juspay)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    oc.url = "github:juspay/oc";
  };

  outputs = { self, nixpkgs, home-manager, oc }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      checks.${system} = {
        opencode-base-test = pkgs.testers.runNixOSTest (import ./test.nix { inherit oc home-manager; });
      };
    };
}
