{
  description = "One-click OpenCode for Juspay";

  nixConfig = {
    extra-substituters = "https://cache.nixos.asia/oss";
    extra-trusted-public-keys = "oss:KO872wNJkCDgmGN3xy9dT89WAhvv13EiKncTtHDItVU=";
  };

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    llm-agents.url = "github:numtide/llm-agents.nix";
    nixpkgs.follows = "llm-agents/nixpkgs";
    nix-agent-wire.url = "github:srid/nix-agent-wire";
    skills = {
      url = "github:juspay/skills";
      flake = false;
    };
  };

  outputs = inputs@{ self, flake-parts, llm-agents, nixpkgs, nix-agent-wire, skills, ... }:
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
          default = pkgs.callPackage ./opencode/packages/default.nix {
            opencode-init = self'.packages.init;
            opencode-oneclick = self'.packages.oneclick;
          };
          opencode = pkgs.opencode;
          init = pkgs.callPackage ./opencode/packages/init.nix { configFile = pkgs.callPackage ./opencode/packages/config.nix { }; };
          oneclick = pkgs.callPackage ./opencode/packages/oneclick.nix {
            configFile = pkgs.callPackage ./opencode/packages/config.nix { };
            skillsSrc = inputs.skills;
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
        default = import ./opencode/modules;
        with-skills = { ... }: {
          imports = [
            self.homeModules.default
            nix-agent-wire.homeModules.opencode
          ];
          programs.opencode.autoWire.dirs = [ skills ];
        };
      };
    };
}
