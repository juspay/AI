{
  description = "One-click Oh My Pi on Juspay's LLM gateway";

  nixConfig = {
    extra-substituters = "https://cache.nixos.asia/oss";
    extra-trusted-public-keys = "oss:KO872wNJkCDgmGN3xy9dT89WAhvv13EiKncTtHDItVU=";
  };

  inputs = {
    llm-agents.url = "github:numtide/llm-agents.nix";
    nixpkgs.follows = "llm-agents/nixpkgs";

    # Skill sources. Not flakes — each is a plain tree we read `skills/` out of
    # when building the OMP plugin (coding-agents/omp/plugin.nix). Nothing is
    # vendored into this repo. juspay/skills is itself an OMP marketplace and
    # plugin (its package.json carries the manifest), so its tree is used as-is.
    juspay-skills = { url = "github:juspay/skills"; flake = false; };
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
          omp = pkgs.llm-agents.omp;
          callOmp = path: lib.callPackageWith (pkgs // { inherit omp; }) (./coding-agents/omp + "/${path}");
          # The skills, built in the store as an OMP plugin package. OMP takes
          # the package itself, via `extensions:`.
          skillsPlugin = callOmp "plugin.nix" { inherit juspay-skills anthropics-skills; };

          # Every variant this flake packages, keyed by its attr name.
          variant = {
            inherit omp;
            omp-juspay-oneclick = callOmp "juspay-oneclick.nix" { inherit skillsPlugin; };
          };

          # What a bare `nix run` offers, in menu order. Each name must be a key
          # of `variant` above — that lookup is the only link between this list
          # and the packages it fronts.
          frontDoor = [
            { name = "omp-juspay-oneclick"; description = "Oh My Pi on the Juspay gateway, skills bundled"; }
            { name = "omp"; description = "Plain Oh My Pi, no config"; }
          ];
        in
        variant // {
          default = pkgs.callPackage ./coding-agents/selector.nix {
            variants = map (v: v // { package = variant.${v.name}; }) frontDoor;
          };
        }
      );

      apps = forAllSystems (system:
        nixpkgs.lib.mapAttrs (_: pkg: { program = nixpkgs.lib.getExe pkg; type = "app"; }) self.packages.${system}
      );
    };
}
