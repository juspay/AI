# What this repo knows about the Juspay LiteLLM gateway: where it is, which key
# unlocks it, and which models the agent starts on.
#
# There is deliberately no model catalog here. OMP ships LiteLLM discovery, so
# it asks the gateway at startup what it serves — ids, context windows,
# capabilities — and a vendored snapshot could only go stale against it.
let
  gatewayUrl = "https://grid.ai.juspay.net";
in
{
  inherit gatewayUrl;

  apiKeyEnv = "JUSPAY_API_KEY";

  # Where the wrapper's prompt sends users to create that key.
  apiKeyUrl = "${gatewayUrl}/dashboard";

  # The models the agent starts on, as role assignments rather than a catalog.
  # Each must be an id the gateway actually serves: nothing here validates them,
  # and OMP falls back to its own first-available model if one goes missing.
  defaultModel = "glm-latest";
  smallModel = "open-fast";
}
