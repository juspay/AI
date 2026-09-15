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
        # overlays.default was removed upstream; shared-nixpkgs is the consumer API.
        overlays = [ llm-agents.overlays.shared-nixpkgs ];
      };
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = pkgsFor system;
          lib = pkgs.lib;
          opencode = pkgs.llm-agents.opencode;
          pi = pkgs.llm-agents.pi;
          omp = pkgs.llm-agents.omp;
          callOc = path: lib.callPackageWith (pkgs // { inherit opencode; }) (./coding-agents/opencode/packages + "/${path}");
          callPi = path: lib.callPackageWith (pkgs // { inherit pi; }) (./coding-agents/pi + "/${path}");
          callOmp = path: lib.callPackageWith (pkgs // { inherit omp; }) (./coding-agents/omp + "/${path}");
          juspayConfigFile = callOc "config.nix" { };
          baseConfigFile = callOc "config.nix" { juspay = false; };
          # Vendored by apm — see .opencode/skills/ and apm.yml
          skillsDir = ./.opencode/skills;
          # Every agent's model file is rendered from the shared gateway
          # provider block (coding-agents/providers.nix), so all three agents
          # agree on model ids and limits.
          piModelsFile = callPi "models-json.nix" { };
          ompModelsFile = callOmp "models-yaml.nix" { };

          # Every variant this flake packages, keyed by its attr name.
          variant = {
            inherit opencode;
            opencode-juspay-editable = callOc "juspay-editable.nix" { configFile = juspayConfigFile; };
            opencode-juspay-oneclick = callOc "juspay-oneclick.nix" { configFile = juspayConfigFile; inherit skillsDir; };
            opencode-oneclick = callOc "oneclick.nix" { configFile = baseConfigFile; inherit skillsDir; };
            inherit pi;
            pi-juspay-oneclick = callPi "juspay-oneclick.nix" { modelsFile = piModelsFile; inherit skillsDir; };
            pi-juspay-editable = callPi "juspay-editable.nix" { modelsFile = piModelsFile; };
            inherit omp;
            omp-juspay-oneclick = callOmp "juspay-oneclick.nix" { modelsFile = ompModelsFile; inherit skillsDir; };
            omp-juspay-editable = callOmp "juspay-editable.nix" { modelsFile = ompModelsFile; };
          };

          # What a bare `nix run` offers, in menu order. Each name must be a key
          # of `variant` above — that lookup is the only link between this list
          # and the packages it fronts.
          frontDoor = [
            { name = "opencode-juspay-oneclick"; description = "Juspay config and skills bundled"; }
            { name = "opencode-oneclick"; description = "Skills bundled, bring your own provider"; }
            { name = "opencode-juspay-editable"; description = "Creates editable Juspay config at ~/.config/opencode/"; }
            { name = "opencode"; description = "Plain OpenCode, no config"; }
            { name = "pi-juspay-oneclick"; description = "pi with Juspay models and skills bundled"; }
            { name = "pi-juspay-editable"; description = "Merges Juspay models into ~/.pi/models.json"; }
            { name = "pi"; description = "Plain pi, no config"; }
            { name = "omp-juspay-oneclick"; description = "Oh My Pi with Juspay models and skills bundled"; }
            { name = "omp-juspay-editable"; description = "Initializes editable Juspay models at ~/.omp/agent/models.yml"; }
            { name = "omp"; description = "Plain Oh My Pi, no config"; }
          ];
        in
        variant // {
          default = pkgs.callPackage ./coding-agents/selector.nix {
            variants = map (v: v // { package = variant.${v.name}; }) frontDoor;
          };
          # Convenience alias: `nix run .#oneclick`
          oneclick = variant.opencode-juspay-oneclick;
        }
      );

      apps = forAllSystems (system:
        nixpkgs.lib.mapAttrs (_: pkg: { program = nixpkgs.lib.getExe pkg; type = "app"; }) self.packages.${system}
      );

      # Home Manager module that installs the opencode *configuration* only
      # (not the binary). System-agnostic — it uses the importing config's
      # pkgs, so it does not depend on this flake's nixpkgs. See the module
      # header for usage.
      homeModules = {
        opencode = ./coding-agents/opencode/home-module.nix;
        default = self.homeModules.opencode;
      };
    };
}
