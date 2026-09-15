{
  description = "One-click coding agents";

  nixConfig = {
    extra-substituters = "https://cache.nixos.asia/oss";
    extra-trusted-public-keys = "oss:KO872wNJkCDgmGN3xy9dT89WAhvv13EiKncTtHDItVU=";
  };

  inputs = {
    llm-agents.url = "github:numtide/llm-agents.nix";
    nixpkgs.follows = "llm-agents/nixpkgs";

    # Skill sources. Not flakes — each is a plain tree we read `skills/` out of
    # when building the OMP plugin (coding-agents/omp/plugin.nix). These
    # replace the APM vendoring that used to commit copies into .claude/ and
    # .opencode/.
    # TODO: repoint to `github:juspay/skills` once juspay/skills#40 (which adds
    # the plugin manifest and marketplace catalogs) merges.
    juspay-skills = { url = "github:juspay/skills/omp-marketplace"; flake = false; };
    anthropics-skills = { url = "github:anthropics/skills"; flake = false; };
    # kolu is deliberately *not* an input — its skill is export-ignored out of
    # every tree a flake fetcher can produce. plugin.nix fetches it directly and
    # explains why.
  };

  outputs = { self, llm-agents, nixpkgs, juspay-skills, anthropics-skills }:
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
          omp = pkgs.llm-agents.omp;
          callOc = path: lib.callPackageWith (pkgs // { inherit opencode; }) (./coding-agents/opencode/packages + "/${path}");
          callOmp = path: lib.callPackageWith (pkgs // { inherit omp; }) (./coding-agents/omp + "/${path}");
          juspayConfigFile = callOc "config.nix" { };
          baseConfigFile = callOc "config.nix" { juspay = false; };
          # The skills, built in the store as an OMP plugin package. OMP takes
          # the package itself (via `extensions:`); opencode has no plugin
          # notion and just wants a directory of `<name>/SKILL.md`, which is
          # the package's `skills/` subdirectory.
          skillsPlugin = callOmp "plugin.nix" { inherit juspay-skills anthropics-skills; };
          skillsDir = "${skillsPlugin}/skills";

          # Every variant this flake packages, keyed by its attr name.
          variant = {
            inherit opencode;
            opencode-juspay-editable = callOc "juspay-editable.nix" { configFile = juspayConfigFile; };
            opencode-juspay-oneclick = callOc "juspay-oneclick.nix" { configFile = juspayConfigFile; inherit skillsDir; };
            opencode-oneclick = callOc "oneclick.nix" { configFile = baseConfigFile; inherit skillsDir; };
            inherit omp;
            omp-juspay-oneclick = callOmp "juspay-oneclick.nix" { inherit skillsPlugin; };
          };

          # What a bare `nix run` offers, in menu order. Each name must be a key
          # of `variant` above — that lookup is the only link between this list
          # and the packages it fronts.
          frontDoor = [
            { name = "opencode-juspay-oneclick"; description = "Juspay config and skills bundled"; }
            { name = "opencode-oneclick"; description = "Skills bundled, bring your own provider"; }
            { name = "opencode-juspay-editable"; description = "Creates editable Juspay config at ~/.config/opencode/"; }
            { name = "opencode"; description = "Plain OpenCode, no config"; }
            { name = "omp-juspay-oneclick"; description = "Oh My Pi on the Juspay gateway, skills bundled"; }
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
