{
  description = "Oh My Pi, Codex, and Claude Code with selectable profiles";

  nixConfig = {
    extra-substituters = "https://cache.nixos.asia/oss";
    extra-trusted-public-keys = "oss:KO872wNJkCDgmGN3xy9dT89WAhvv13EiKncTtHDItVU=";
  };

  inputs = {
    # Oh My Pi from upstream's own flake, pinned to a *release tag* rather than
    # a branch. The tag is the whole point: `update-flake.yml` resolves the
    # latest release daily and rewrites this ref, and the lock makes the pin
    # reproducible in between.
    oh-my-pi.url = "github:can1357/oh-my-pi/v18.2.4";

    # Each packaging repo tracks its current release binary and keeps its own
    # nixpkgs so packaging updates do not depend on OMP's build dependencies.
    codex-cli.url = "github:sadjow/codex-cli-nix";
    claude-code.url = "github:sadjow/claude-code-nix";

    # Upstream's package set, followed rather than shadowed. omp is built from
    # source there, so its derivation hash is the interface to every binary
    # cache — ours included — and overriding `oh-my-pi.inputs.nixpkgs` would
    # re-key that derivation for nothing. Following it here keeps the
    # wrappers and VM tests on the same package set, using the very glibc the omp binary was linked against, instead of a second, newer
    # one that could drift the other way.
    nixpkgs.follows = "oh-my-pi/nixpkgs";

    # Portable skill sources. Nothing is vendored into this repo; the shared
    # profiles use juspay/skills directly, while kolu's plugin is passed through whole.
    juspay-skills = { url = "github:juspay/skills"; flake = false; };

    # kolu, for its `agent-plugin/` directory: a standard Agent Plugins 1.0.0
    # package (plugin.json + mcp.json + skills/kolu/SKILL.md) that omp loads
    # whole, rather than a skill we copy into our own bundle. It is a plain
    # tree like juspay-skills — nothing here builds kolu — and unlike the skill
    # it replaces, this path is *not* export-ignored, so an ordinary flake
    # input can see it and `nix flake update` can bump it.
    kolu = { url = "github:juspay/kolu"; flake = false; };
  };

  outputs = { self, nixpkgs, oh-my-pi, codex-cli, claude-code, juspay-skills, kolu }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
      pkgsFor = system: import nixpkgs { inherit system; };
    in
    {
      profiles = nixpkgs.lib.genAttrs [ "vanilla" "kolu" "juspay" ]
        (name: import (./profiles + "/${name}.nix") {
          sources = { inherit juspay-skills kolu; };
        });

      lib.mkLaunchers = import ./lib/mk-launchers.nix {
        inherit oh-my-pi codex-cli claude-code;
      };

      legacyPackages = forAllSystems (system:
        nixpkgs.lib.mapAttrs (_: profile: self.lib.mkLaunchers {
          pkgs = pkgsFor system;
          inherit profile;
        }) self.profiles
      );

      packages = forAllSystems (system:
        let
          pkgs = pkgsFor system;
          launchers = self.legacyPackages.${system};
        in
        nixpkgs.lib.mapAttrs (_: value: value.picker) launchers // {
          default = pkgs.callPackage ./coding-agents/profile-picker.nix {
            inherit launchers;
            inherit (self) profiles;
          };
        }
      );

      apps = forAllSystems (system:
        nixpkgs.lib.mapAttrs (_: pkg: { program = nixpkgs.lib.getExe pkg; type = "app"; }) self.packages.${system}
      );
    };
}
