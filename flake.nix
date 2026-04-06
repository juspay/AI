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
    skills.url = "github:juspay/skills";
    skills.flake = false;
  };

  outputs = inputs@{ self, flake-parts, llm-agents, nixpkgs, skills, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];

      perSystem = { self', lib, pkgs, system, ... }:
        let
          opencode = pkgs.llm-agents.opencode;
          claude-code = pkgs.llm-agents.claude-code;
          # callPackageWith auto-injects opencode into package functions that accept it
          callOc = path: lib.callPackageWith (pkgs // { inherit opencode; }) (./coding-agents/opencode/packages + "/${path}");
          callCc = path: lib.callPackageWith (pkgs // { inherit claude-code; }) (./coding-agents/claude-code + "/${path}");
          juspayConfigFile = callOc "config.nix" { };
          baseConfigFile = callOc "config.nix" { settings = import ./coding-agents/opencode/settings; };
          skillsSrc = skills;
        in
        {
          _module.args.pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [ llm-agents.overlays.default ];
          };

          packages = {
            default = callOc "default.nix" {
              inherit (self'.packages) opencode-juspay-editable opencode-juspay-oneclick opencode-oneclick claude-code-juspay-oneclick;
            };
            inherit opencode;
            opencode-juspay-editable = callOc "juspay-editable.nix" {
              configFile = juspayConfigFile;
            };
            opencode-juspay-oneclick = callOc "juspay-oneclick.nix" {
              configFile = juspayConfigFile;
              inherit skillsSrc;
            };
            opencode-oneclick = callOc "oneclick.nix" {
              configFile = baseConfigFile;
              inherit skillsSrc;
            };
            claude-code-juspay-oneclick = callCc "juspay-oneclick.nix" {
              inherit skillsSrc;
            };
          };

          apps = lib.mapAttrs (_: pkg: { program = lib.getExe pkg; }) self'.packages;
        };

    };
}
