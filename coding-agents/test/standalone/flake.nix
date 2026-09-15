{
  description = "Standalone wrapper package tests";

  inputs = {
    # The flake under test — override it with `--override-input ai .` from the
    # repo root (what `just test` and CI do). Its nixpkgs drives the VMs too, so
    # the test closures share store paths with the packages under test.
    ai.url = "github:juspay/AI";
    nixpkgs.follows = "ai/nixpkgs";
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
