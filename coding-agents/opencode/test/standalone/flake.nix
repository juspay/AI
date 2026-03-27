{
  description = "OpenCode standalone package tests";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    oc.url = "github:juspay/oc";
  };

  outputs = { self, nixpkgs, oc }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      mkTest = file: pkgs.testers.runNixOSTest (import file { inherit oc; });
    in
    {
      checks.${system} = {
        opencode-juspay-editable = mkTest ./test-juspay-editable.nix;
        opencode-juspay-oneclick = mkTest ./test-juspay-oneclick.nix;
        opencode-oneclick = mkTest ./test-oneclick.nix;
      };
    };
}
