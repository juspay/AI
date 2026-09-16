{
  description = "One-click Oh My Pi on Juspay's LLM gateway";

  nixConfig = {
    extra-substituters = "https://cache.nixos.asia/oss";
    extra-trusted-public-keys = "oss:KO872wNJkCDgmGN3xy9dT89WAhvv13EiKncTtHDItVU=";
  };

  inputs = {
    # Oh My Pi from upstream's own flake, pinned to a *release tag* rather than
    # a branch. The tag is the whole point: `update-flake.yml` resolves the
    # latest release daily and rewrites this ref, and the lock makes the pin
    # reproducible in between.
    oh-my-pi.url = "github:can1357/oh-my-pi/v18.2.1";

    # Upstream's package set, followed rather than shadowed. omp is built from
    # source there, so its derivation hash is the interface to every binary
    # cache — ours included — and overriding `oh-my-pi.inputs.nixpkgs` would
    # re-key that derivation for nothing. Following it here also leaves this
    # repo with a single package set: the wrapper and the VM tests then use the
    # very glibc the omp binary was linked against, instead of a second, newer
    # one that could drift the other way.
    nixpkgs.follows = "oh-my-pi/nixpkgs";

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

  outputs = { self, nixpkgs, oh-my-pi, juspay-skills, anthropics-skills }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
      pkgsFor = system: import nixpkgs { inherit system; };
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = pkgsFor system;
          # The skills, built in the store as an OMP plugin package. OMP takes
          # the package itself, via `extensions:`.
          skillsPlugin = pkgs.callPackage ./coding-agents/omp/plugin.nix {
            inherit juspay-skills anthropics-skills;
          };
          omp = pkgs.callPackage ./coding-agents/omp {
            inherit skillsPlugin;
            # Upstream's own build, on upstream's own package set. We only wrap
            # it; the arg is spelled out because nothing in `pkgs` provides it.
            omp = oh-my-pi.packages.${system}.default;
          };
        in
        {
          default = omp;
          # The same derivation under the name users type: `nix run
          # github:juspay/AI#omp`. There is only one package here, so this is an
          # alias, not a variant.
          inherit omp;
        }
      );

      apps = forAllSystems (system:
        nixpkgs.lib.mapAttrs (_: pkg: { program = nixpkgs.lib.getExe pkg; type = "app"; }) self.packages.${system}
      );
    };
}
