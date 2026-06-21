let
  # All models accept text+image input, text output; name = attr key.
  # reasoningEffort (optional) marks the model as a reasoning model and is
  # forwarded as the OpenAI-compatible `reasoning_effort` request field —
  # @ai-sdk/openai-compatible maps the camelCase key to snake_case for us.
  mkModel = name: { context, output, reasoningEffort ? null }:
    let
      base = {
        inherit name;
        modalities = { input = [ "text" "image" ]; output = [ "text" ]; };
        limit = { inherit context output; };
      };
    in
    if reasoningEffort == null then base
    else base // {
      reasoning = true;
      options = { inherit reasoningEffort; };
    };

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
    # glm-latest is GLM-5.2, which supports graduated reasoning effort up to
    # "max" (its top tier). Enable max thinking by default.
    glm-latest              = { context = 202752;  output = 32000; reasoningEffort = "max"; };
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
