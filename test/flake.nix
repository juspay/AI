{
  description = "Juspay distribution integration tests";

  inputs = {
    # Use the distribution in this checkout without a published revision.
    ai.url = "path:..";
    nixpkgs.follows = "ai/agent-distro/nixpkgs";
  };

  outputs = { nixpkgs, ai, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      packages = ai.packages.${system};
      tests = import "${ai.inputs.agent-distro}/test/lib.nix" {
        inherit pkgs;
        profile = ai.profiles.juspay;
        launchers = { inherit (packages) omp codex claude; picker = packages.default; };
        inherit (ai.inputs.agent-distro.lib) mkLaunchers;
      };
    in {
      # All checks apply: this profile has plugins, a gateway, and Kolu MCP.
      checks.${system} = {
        inherit (tests) omp codex claude picker gateway gatewayEnv
          ompPlugins codexPlugins claudePlugins ompKolu codexKolu claudeKolu;
      };
    };
}
