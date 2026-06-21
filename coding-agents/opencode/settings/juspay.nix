let
  # All models accept text+image input, text output; name = attr key.
  # reasoningEffort (optional) marks the model as a reasoning model and is
  # forwarded as the OpenAI-compatible `reasoning_effort` request field —
  # @ai-sdk/openai-compatible maps the camelCase key to snake_case for us.
  # id (optional) sets the wire model id when the attr key differs from the
  # gateway's model name — used to expose one gateway model at several
  # reasoning-effort tiers.
  mkModel = name: { context, output, reasoningEffort ? null, id ? null }:
    let
      base = {
        inherit name;
        modalities = { input = [ "text" "image" ]; output = [ "text" ]; };
        limit = { inherit context output; };
      } // (if id == null then { } else { inherit id; });
    in
    if reasoningEffort == null then base
    else base // {
      reasoning = true;
      options = { inherit reasoningEffort; };
    };

  # GLM-5.2 (glm-latest and its effort-tier siblings) share a 1M-token context
  # window (the old 202752 was a copy-paste default). output stays at 32000:
  # OpenCode caps the wire max_tokens at 32000 for this custom-provider model
  # regardless of this field (verified), so a higher value would only shrink the
  # usable input budget without raising the real output limit.
  glmLimits = { context = 1000000; output = 32000; };

  models = builtins.mapAttrs mkModel {
    open-large              = { context = 202752;  output = 32000; };
    open-fast               = { context = 196000;  output = 32000; };
    open-vision             = { context = 262144;  output = 32000; };
    claude-opus-4-5         = { context = 1000000; output = 128000; };
    claude-opus-4-6         = { context = 1000000; output = 128000; };
    claude-sonnet-4-6       = { context = 200000;  output = 64000; };
    claude-sonnet-4-5       = { context = 200000;  output = 32000; };
    glm-flash-experimental  = { context = 262144;  output = 32000; };
    gemini-3-pro-preview    = { context = 1048576; output = 65535; };
    gemini-3-flash-preview  = { context = 1048576; output = 65535; };
    minimax-m2              = { context = 202752;  output = 32000; };
    # glm-latest is GLM-5.2. Its default reasoning is left untouched (no
    # reasoning_effort sent — the gateway default, which is thinking-on). The
    # effort tiers below are sibling picker entries that target the same gateway
    # model via `id`; GLM-5.2 collapses low/medium into "high", so max / high /
    # off are the only distinct levels.
    glm-latest              = glmLimits;
    glm-max                 = glmLimits // { reasoningEffort = "max";  id = "glm-latest"; };
    glm-high                = glmLimits // { reasoningEffort = "high"; id = "glm-latest"; };
    glm-fast                = glmLimits // { reasoningEffort = "none"; id = "glm-latest"; };
    kimi-latest             = { context = 262000;  output = 32000; };
  };
in
{
  model = "litellm/glm-latest";
  small_model = "litellm/open-fast";
  agent.explore = { mode = "subagent"; model = "litellm/open-fast"; };
  provider.litellm = {
    npm = "@ai-sdk/openai-compatible";
    name = "Juspay";
    options = {
      baseURL = "https://grid.ai.juspay.net";
      apiKey = "{env:JUSPAY_API_KEY}";
      timeout = 600000;
    };
    inherit models;
  };
}
