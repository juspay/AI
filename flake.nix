{
  description = "One-click access to OpenCode for Nix users";

  nixConfig = {
    extra-substituters = "https://cache.nixos.asia/oss";
    extra-trusted-public-keys = "oss:KO872wNJkCDgmGN3xy9dT89WAhvv13EiKncTtHDItVU=";
  };

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    llm-agents.url = "github:numtide/llm-agents.nix";
    nixpkgs.follows = "llm-agents/nixpkgs";
  };

  outputs = inputs@{ self, flake-parts, llm-agents, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];

      perSystem = { self', lib, pkgs, system, inputs', ... }: {
        _module.args.pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        packages = {
          default = inputs'.llm-agents.packages.opencode;
          juspay = import ./modules/juspay/package.nix { inherit pkgs lib; };
        };

        apps = {
          default.program = lib.getExe' self'.packages.default "opencode";
          juspay.program = lib.getExe' self'.packages.juspay "opencode";
        };
      };

      flake.homeModules.default = import ./modules;
    };
}
