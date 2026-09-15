let
  catalog = import ../../catalog.nix;

  # Adapt the gateway snapshot (see coding-agents/catalog.nix) to opencode's
  # provider model schema. name = attr key; reasoningEffort is forwarded as
  # the OpenAI-compatible `reasoning_effort` request field —
  # @ai-sdk/openai-compatible maps the camelCase key to snake_case for us.
  # `vision` is the gateway's answer; when it says nothing we keep offering
  # image input, which is what opencode did before the snapshot existed.
  mkModel = name:
    { context, output, reasoning ? false, vision ? true, reasoningEffort ? null, id ? null }:
    let
      base = {
        inherit name;
        modalities = {
          input = if vision then [ "text" "image" ] else [ "text" ];
          output = [ "text" ];
        };
        limit = { inherit context output; };
      } // (if id == null then { } else { inherit id; });
    in
    base
    // (if reasoning then { inherit reasoning; } else { })
    // (if reasoningEffort == null then { } else { options = { inherit reasoningEffort; }; });

  # GLM-5.2 collapses low/medium into "high", so the picker exposes the same
  # gateway model at the three distinct effort tiers below (glm-latest itself
  # stays at the gateway default, thinking-on, with no reasoning_effort sent).
  glmLimits = catalog.models.glm-latest;
  effortTiers = {
    glm-max  = glmLimits // { reasoning = true; reasoningEffort = "max";  id = "glm-latest"; };
    glm-high = glmLimits // { reasoning = true; reasoningEffort = "high"; id = "glm-latest"; };
    glm-fast = glmLimits // { reasoningEffort = "none"; id = "glm-latest"; };
  };

  models = builtins.mapAttrs mkModel (catalog.models // effortTiers);
in
{
  # The catalog's recommended models, so a rename there cannot leave these
  # pointing at a model that no longer exists.
  model = "litellm/${catalog.defaultModel}";
  small_model = "litellm/${catalog.smallModel}";
  agent.explore = { mode = "subagent"; model = "litellm/${catalog.smallModel}"; };
  provider.litellm = {
    npm = "@ai-sdk/openai-compatible";
    name = "Juspay";
    options = {
      baseURL = catalog.gatewayUrl;
      apiKey = "{env:${catalog.apiKeyEnv}}";
      timeout = 600000;
    };
    inherit models;
  };
}
