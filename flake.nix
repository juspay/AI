{
  description = "Moved: the Juspay distribution is a profile of github:juspay/agent-distro";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = lib.genAttrs systems;

      moved = ''
        juspay/AI has moved. The Juspay distribution is the `juspay` profile of
        github:juspay/agent-distro:

          AI_PROFILE=juspay nix run github:juspay/agent-distro
          AI_PROFILE=juspay AI_HARNESS=omp nix run github:juspay/agent-distro -- --version

        Flakes that used juspay/AI as an input should compose
        `agent-distro.lib.mkLaunchers` with `agent-distro.profiles.juspay`.
        See https://github.com/juspay/agent-distro#readme.
      '';

      # `nix run github:juspay/AI` keeps working by delegating to agent-distro's
      # unpinned default branch, so this repo needs no further lock bumps.
      shim = system: nixpkgs.legacyPackages.${system}.writeShellApplication {
        name = "ai";
        text = ''
          export AI_PROFILE=juspay
          exec nix run github:juspay/agent-distro -- "$@"
        '';
      };
    in
    {
      apps = forAllSystems (system: {
        default = { type = "app"; program = lib.getExe (shim system); };
      });

      # Building or importing the old package fails with the migration note
      # rather than producing a launcher that no longer receives updates.
      packages = forAllSystems (_: { default = throw moved; });
    };
}
