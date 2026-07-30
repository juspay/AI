# Single source of truth for the Juspay LiteLLM gateway
# (https://grid.ai.juspay.net) model catalog, shared by every coding agent
# this repo packages (opencode, pi). Adding or tuning a model here updates
# all agents at once, keeping their model ids and limits in sync.
#
# Each entry:
#   context   - context window in tokens
#   output    - max output tokens
#   reasoning - whether the model reasons by default (optional)
let
  # GLM-5.2 shares a 1M-token context window (the old 202752 was a copy-paste
  # default). output stays at 32000: custom-provider clients cap the wire
  # max_tokens at 32000 for this model regardless of this field (verified
  # with opencode), so a higher value would only shrink the usable input
  # budget without raising the real output limit.
  glmLimits = { context = 1000000; output = 32000; };
in
{
  gatewayUrl = "https://grid.ai.juspay.net";
  apiKeyEnv = "JUSPAY_API_KEY";

  # All models accept text+image input and produce text output.
  #
  # glm-latest is GLM-5.2 and reasons by default. Each agent exposes the
  # effort tiers its own way: opencode gets sibling picker entries (glm-max /
  # glm-high / glm-fast — injected in opencode/settings/juspay.nix), pi takes
  # a per-session thinking level via `--model litellm/glm-latest:max` etc.
  models = {
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
    glm-latest              = glmLimits // { reasoning = true; };
    kimi-latest             = { context = 262000;  output = 32000; };
    kimi-k3                 = { context = 256000;  output = 32000; };
  };
}
