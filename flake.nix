{
  description = "One-click coding agents for Juspay";

  nixConfig = {
    extra-substituters = "https://cache.nixos.asia/oss";
    extra-trusted-public-keys = "oss:KO872wNJkCDgmGN3xy9dT89WAhvv13EiKncTtHDItVU=";
  };

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    llm-agents.url = "github:numtide/llm-agents.nix";
    nixpkgs.follows = "llm-agents/nixpkgs";
    nix-agent-wire.url = "github:srid/nix-agent-wire";
  };

  outputs = inputs@{ self, flake-parts, llm-agents, nixpkgs, nix-agent-wire, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];

      perSystem = { self', lib, pkgs, system, inputs', ... }: {
        _module.args.pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            llm-agents.overlays.default
            # Expose opencode directly for callPackage to auto-fill the argument
            (final: prev: { opencode = prev.llm-agents.opencode; })
          ];
        };

        packages = {
          default = pkgs.callPackage ./coding-agents/opencode/packages/default.nix {
            opencode-init = self'.packages.init;
            opencode-oneclick = self'.packages.oneclick;
          };
          opencode = pkgs.opencode;
          init = pkgs.callPackage ./coding-agents/opencode/packages/init.nix { configFile = pkgs.callPackage ./coding-agents/opencode/packages/config.nix { }; };
          oneclick = pkgs.callPackage ./coding-agents/opencode/packages/oneclick.nix {
            configFile = pkgs.callPackage ./coding-agents/opencode/packages/config.nix { };
            skillsSrc = self + "/.agents";
          };
        };

        apps = {
          default.program = lib.getExe' self'.packages.default "opencode";
          opencode.program = lib.getExe' self'.packages.opencode "opencode";
          init.program = lib.getExe' self'.packages.init "opencode";
          oneclick.program = lib.getExe' self'.packages.oneclick "opencode";
        };
      };

      flake.homeModules = {
        default = import ./coding-agents/opencode/modules;
        with-skills = { ... }: {
          imports = [
            self.homeModules.default
            nix-agent-wire.homeModules.opencode
          ];
          programs.opencode.autoWire.dirs = [ (self + "/.agents") ];
        };
      };
    };
}
