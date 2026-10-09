{
  description = "Moved: the Juspay distribution is the agent-distro profile in github:juspay/skills";

  outputs = { self }:
    let
      moved = throw ''
        juspay/AI has moved. Run:

          nix run github:juspay/agent-distro -- github:juspay/skills
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
