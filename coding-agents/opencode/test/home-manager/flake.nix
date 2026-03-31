{
  description = "OpenCode home-manager module tests";

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
      mkTest = file: pkgs.testers.runNixOSTest (import file { inherit oc home-manager; });
    in
    {
      checks.${system} = {
        opencode-base = mkTest ./test-base.nix;
        opencode-juspay = mkTest ./test-juspay.nix;
      };
    };
}
