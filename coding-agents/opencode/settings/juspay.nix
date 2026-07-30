let
  catalog = import ../../catalog.nix;

  # Adapt the shared catalog (see coding-agents/catalog.nix) to opencode's
  # provider model schema. name = attr key; reasoningEffort is forwarded as
  # the OpenAI-compatible `reasoning_effort` request field —
  # @ai-sdk/openai-compatible maps the camelCase key to snake_case for us.
  mkModel = name:
    { context, output, reasoning ? false, reasoningEffort ? null, id ? null }:
    let
      base = {
        inherit name;
        modalities = { input = [ "text" "image" ]; output = [ "text" ]; };
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
  model = "litellm/glm-latest";
  small_model = "litellm/open-fast";
  agent.explore = { mode = "subagent"; model = "litellm/open-fast"; };
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
