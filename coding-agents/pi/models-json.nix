{ pkgs }:
let
  catalog = import ../catalog.nix;
  jsonFormat = pkgs.formats.json { };

  # Adapt the shared catalog (see coding-agents/catalog.nix) to pi's
  # models.json schema. pi natively supports per-session thinking levels via
  # `--model litellm/glm-latest:off|low|medium|high|max` on the reasoning
  # model, so the catalog's plain gateway ids suffice here.
  #
  # Verified against grid.ai.juspay.net with pi 0.83.0: both the `developer`
  # role and the `reasoning_effort` field on reasoning models are accepted,
  # so no provider-level `compat` overrides are needed.
  mkModel = name:
    { context, output, reasoning ? false, ... }:
    {
      id = name;
      inherit name reasoning;
      input = [ "text" "image" ];
      contextWindow = context;
      maxTokens = output;
    };
in
jsonFormat.generate "pi-models.json" {
  providers.litellm = {
    baseUrl = catalog.gatewayUrl;
    api = "openai-completions";
    apiKey = "\$${catalog.apiKeyEnv}";
    models = pkgs.lib.mapAttrsToList mkModel catalog.models;
  };
}
