{
  description = "Standalone wrapper package tests";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # The flake under test — override it with `--override-input ai .` from the
    # repo root (what `just test` and vira.hs do).
    ai.url = "github:juspay/AI";
  };

  outputs = { self, nixpkgs, ai }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      mkTest = file: pkgs.testers.runNixOSTest (import file { inherit ai; });
    in
    {
      checks.${system} = {
        opencode-juspay-editable = mkTest ./test-juspay-editable.nix;
        opencode-juspay-oneclick = mkTest ./test-juspay-oneclick.nix;
        opencode-oneclick = mkTest ./test-oneclick.nix;
        pi-oneclick = mkTest ./test-pi-oneclick.nix;
        omp-oneclick = mkTest ./test-omp-oneclick.nix;
      };
    };
}
