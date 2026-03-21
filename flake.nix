{
  description = "One-click coding agents";

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
            # Expose packages directly for callPackage to auto-fill the argument
            (final: prev: {
              opencode = prev.llm-agents.opencode;
              claude-code = prev.llm-agents.claude-code;
            })
          ];
        };

        packages = {
          default = pkgs.callPackage ./coding-agents/opencode/packages/default.nix {
            inherit (self'.packages) opencode-juspay-editable opencode-juspay-oneclick opencode-oneclick claude-code claude-code-oneclick claude-code-juspay-oneclick;
          };
          opencode = pkgs.opencode;
          opencode-juspay-editable = pkgs.callPackage ./coding-agents/opencode/packages/juspay-editable.nix {
            configFile = pkgs.callPackage ./coding-agents/opencode/packages/config.nix { };
          };
          opencode-juspay-oneclick = pkgs.callPackage ./coding-agents/opencode/packages/juspay-oneclick.nix {
            configFile = pkgs.callPackage ./coding-agents/opencode/packages/config.nix { };
            skillsSrc = self + "/.agents";
          };
          opencode-oneclick = pkgs.callPackage ./coding-agents/opencode/packages/oneclick.nix {
            configFile = pkgs.callPackage ./coding-agents/opencode/packages/config.nix {
              settings = import ./coding-agents/opencode/settings;
            };
            skillsSrc = self + "/.agents";
          };
          claude-code = pkgs.claude-code;
          claude-code-oneclick = pkgs.callPackage ./coding-agents/claude-code/packages/oneclick.nix {
            skillsSrc = self + "/.agents";
          };
          claude-code-juspay-oneclick = pkgs.callPackage ./coding-agents/claude-code/packages/juspay-oneclick.nix {
            skillsSrc = self + "/.agents";
          };
        };

        apps = {
          default.program = lib.getExe' self'.packages.default "opencode";
          opencode.program = lib.getExe' self'.packages.opencode "opencode";
          opencode-juspay-editable.program = lib.getExe' self'.packages.opencode-juspay-editable "opencode";
          opencode-juspay-oneclick.program = lib.getExe' self'.packages.opencode-juspay-oneclick "opencode";
          opencode-oneclick.program = lib.getExe' self'.packages.opencode-oneclick "opencode";
          claude-code.program = lib.getExe' self'.packages.claude-code "claude";
          claude-code-oneclick.program = lib.getExe' self'.packages.claude-code-oneclick "claude";
          claude-code-juspay-oneclick.program = lib.getExe' self'.packages.claude-code-juspay-oneclick "claude";
        };
      };

      flake.homeModules = {
        opencode = { ... }: {
          imports = [
            (import ./coding-agents/opencode/home)
            nix-agent-wire.homeModules.opencode
          ];
        };
        opencode-juspay = { ... }: {
          imports = [
            (import ./coding-agents/opencode/home)
            (import ./coding-agents/opencode/home/juspay.nix)
            nix-agent-wire.homeModules.opencode
          ];
        };
        claude-code = { ... }: {
          imports = [
            (import ./coding-agents/claude-code/home)
            nix-agent-wire.homeModules.claude-code
          ];
        };
        claude-code-juspay = { ... }: {
          imports = [
            (import ./coding-agents/claude-code/home)
            (import ./coding-agents/claude-code/home/juspay.nix)
            nix-agent-wire.homeModules.claude-code
          ];
        };
      };
    };
}
