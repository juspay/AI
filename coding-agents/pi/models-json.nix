{ pkgs }:
let
  catalog = import ../catalog.nix;
in
# pi's models.json spells the key as a shell-style reference to the env var; OMP
# (../omp/models-yaml.nix) takes the bare name instead.
(pkgs.formats.json { }).generate "pi-models.json"
  (import ../providers.nix { apiKey = "\$${catalog.apiKeyEnv}"; })
