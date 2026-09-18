{
  description = "Juspay distribution of Oh My Pi, Codex, and Claude Code";

  nixConfig = {
    extra-substituters = "https://cache.nixos.asia/oss";
    extra-trusted-public-keys = "oss:KO872wNJkCDgmGN3xy9dT89WAhvv13EiKncTtHDItVU=";
  };

  inputs = {
    # Framework, adapters, pickers, and harness pins. Harness versions follow
    # agent-distro; our daily update moves it and Juspay's plugin sources.
    # Re-lock to the default branch once agent-distro PR 1 merges.
    agent-distro.url = "github:juspay/agent-distro/init";

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

  outputs = { self, agent-distro, juspay-skills, kolu }:
    let profile = import ./profile.nix { inherit juspay-skills kolu; };
    in agent-distro.lib.mkFlake { inherit profile; } // {
      # Resolved data for consumers, including overrides such as gateway = null.
      profiles.juspay = profile;
    };
}
