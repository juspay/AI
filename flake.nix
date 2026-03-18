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
            # Expose opencode directly for callPackage to auto-fill the argument
            (final: prev: { opencode = prev.llm-agents.opencode; })
          ];
        };

        packages = {
          default = pkgs.callPackage ./coding-agents/opencode/packages/default.nix {
            inherit (self'.packages) opencode-juspay opencode-juspay-oneclick opencode-oneclick;
          };
          opencode = pkgs.opencode;
          opencode-juspay = pkgs.callPackage ./coding-agents/opencode/packages/juspay.nix {
            configFile = pkgs.callPackage ./coding-agents/opencode/packages/config.nix { };
          };
          opencode-juspay-oneclick = pkgs.callPackage ./coding-agents/opencode/packages/juspay-oneclick.nix {
            configFile = pkgs.callPackage ./coding-agents/opencode/packages/config.nix { };
            skillsSrc = self + "/.agents";
          };
          opencode-oneclick = pkgs.callPackage ./coding-agents/opencode/packages/oneclick.nix {
            configFile = pkgs.callPackage ./coding-agents/opencode/packages/config.nix {
              settings = {
                autoupdate = true;
                mcp.deepwiki = { type = "remote"; url = "https://mcp.deepwiki.com/mcp"; enabled = true; };
                plugin = [ ];
              };
            };
            skillsSrc = self + "/.agents";
          };
        };

        apps = {
          default.program = lib.getExe' self'.packages.default "opencode";
          opencode.program = lib.getExe' self'.packages.opencode "opencode";
          opencode-juspay.program = lib.getExe' self'.packages.opencode-juspay "opencode";
          opencode-juspay-oneclick.program = lib.getExe' self'.packages.opencode-juspay-oneclick "opencode";
          opencode-oneclick.program = lib.getExe' self'.packages.opencode-oneclick "opencode";
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
            (import ./coding-agents/opencode/home/juspay.nix)
            nix-agent-wire.homeModules.opencode
          ];
        };
      };
    };
}
