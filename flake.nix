{
  description = "Moved: the Juspay distribution is a profile of github:juspay/agent-distro";

  outputs = { self }:
    let
      moved = throw ''
        juspay/AI has moved. The Juspay distribution is the `juspay` profile of
        github:juspay/agent-distro:

          AI_PROFILE=juspay nix run github:juspay/agent-distro
          AI_PROFILE=juspay AI_HARNESS=omp nix run github:juspay/agent-distro -- --version

        Flakes that used juspay/AI as an input should compose
        `agent-distro.lib.mkLaunchers` with `agent-distro.profiles.juspay`.
        See https://github.com/juspay/agent-distro#readme.
      '';
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = f: builtins.listToAttrs (map (system: { name = system; value = f; }) systems);
    in
    {
      # Every old entry point fails with the notice above; nothing is built here.
      packages = forAllSystems { default = moved; omp = moved; codex = moved; claude = moved; };
      apps = forAllSystems { default = moved; omp = moved; codex = moved; claude = moved; };
    };
}
