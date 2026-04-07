{
  description = "One-click coding agents";

  nixConfig = {
    extra-substituters = "https://cache.nixos.asia/oss";
    extra-trusted-public-keys = "oss:KO872wNJkCDgmGN3xy9dT89WAhvv13EiKncTtHDItVU=";
  };

  inputs = {
    llm-agents.url = "github:numtide/llm-agents.nix";
    nixpkgs.follows = "llm-agents/nixpkgs";
  };

  outputs = { self, llm-agents, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
      pkgsFor = system: import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ llm-agents.overlays.default ];
      };
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = pkgsFor system;
          lib = pkgs.lib;
          opencode = pkgs.llm-agents.opencode;
          callOc = path: lib.callPackageWith (pkgs // { inherit opencode; }) (./coding-agents/opencode/packages + "/${path}");
          juspayConfigFile = callOc "config.nix" { };
          baseConfigFile = callOc "config.nix" { settings = import ./coding-agents/opencode/settings; };
          # Vendored by apm — see .opencode/skills/ and apm.yml
          skillsDir = ./.opencode/skills;
        in
        {
          default = callOc "default.nix" {
            inherit opencode;
            opencode-juspay-editable = self.packages.${system}.opencode-juspay-editable;
            opencode-juspay-oneclick = self.packages.${system}.opencode-juspay-oneclick;
            opencode-oneclick = self.packages.${system}.opencode-oneclick;
          };
          inherit opencode;
          opencode-juspay-editable = callOc "juspay-editable.nix" {
            configFile = juspayConfigFile;
          };
          opencode-juspay-oneclick = callOc "juspay-oneclick.nix" {
            configFile = juspayConfigFile;
            inherit skillsDir;
          };
          opencode-oneclick = callOc "oneclick.nix" {
            configFile = baseConfigFile;
            inherit skillsDir;
          };
        }
      );

      apps = forAllSystems (system:
        nixpkgs.lib.mapAttrs (_: pkg: { program = nixpkgs.lib.getExe pkg; type = "app"; }) self.packages.${system}
      );
    };
}
