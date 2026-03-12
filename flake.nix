{
  description = "One-click access to OpenCode for Nix users";

  nixConfig = {
    extra-substituters = "https://cache.nixos.asia/oss";
    extra-trusted-public-keys = "oss:KO872wNJkCDgmGN3xy9dT89WAhvv13EiKncTtHDItVU=";
  };

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  outputs = inputs@{ self, flake-parts, llm-agents, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];

      perSystem = { self', lib, system, ... }: {
        packages.default = llm-agents.packages.${system}.opencode;

        apps.default = {
          type = "app";
          program = lib.getExe' self'.packages.default "opencode";
        };
      };
    };
}
