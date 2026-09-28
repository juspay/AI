{
  description = "Moved: the Juspay distribution is a profile of github:juspay/agent-distro";

  outputs = { self }:
    let
      moved = throw ''
        juspay/AI has moved. Run:

          AI_PROFILE=juspay nix run github:juspay/agent-distro
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
