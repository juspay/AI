{ pkgs }:
let
  catalog = import ../catalog.nix;
  yamlFormat = pkgs.formats.yaml { };
in
yamlFormat.generate "omp-models.yml" {
  providers.litellm = {
    baseUrl = catalog.gatewayUrl;
    api = "openai-completions";
    # OMP resolves bare environment-variable names, unlike pi's $VAR syntax.
    apiKey = catalog.apiKeyEnv;
    models = pkgs.lib.mapAttrsToList
      (name: { context, output, reasoning ? false, ... }: {
        id = name;
        inherit name reasoning;
        input = [ "text" "image" ];
        contextWindow = context;
        maxTokens = output;
      })
      catalog.models;
  };
}
