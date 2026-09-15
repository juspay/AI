{ pkgs }:
let
  catalog = import ../catalog.nix;
in
# OMP resolves bare environment-variable names, unlike pi's $VAR syntax.
(pkgs.formats.yaml { }).generate "omp-models.yml"
  (import ../providers.nix { apiKey = catalog.apiKeyEnv; })
