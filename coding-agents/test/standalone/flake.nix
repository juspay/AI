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
        vanilla = mkTest ./test-vanilla.nix;
        omp = mkTest ./test-omp.nix;
        codex = mkTest ./test-codex.nix;
        claude = mkTest ./test-claude.nix;
        picker = mkTest ./test-picker.nix;
      };
    };
}
