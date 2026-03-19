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
    in {
      checks.${system} = {
        opencode-juspay-editable = pkgs.testers.runNixOSTest (import ./test-juspay-editable.nix { inherit oc; });
        opencode-juspay-oneclick = pkgs.testers.runNixOSTest (import ./test-juspay-oneclick.nix { inherit oc; });
        opencode-oneclick = pkgs.testers.runNixOSTest (import ./test-oneclick.nix { inherit oc; });
      };
    };
}
