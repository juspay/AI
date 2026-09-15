# What this repo's agents know about the Juspay LiteLLM gateway: our policy —
# where the gateway is, which key unlocks it, which model we recommend — wrapped
# around a snapshot of what the gateway actually serves.
#
# OMP asks the gateway itself at runtime (it ships LiteLLM discovery), so the
# snapshot is for the agent that cannot: opencode's provider catalog is
# models.dev plus models declared in config, and a private gateway is in
# neither. It is a snapshot rather than a hand-kept list because availability is
# per key and limits move — refresh it with `just refresh-gateway-models`.
let
  gatewayUrl = "https://grid.ai.juspay.net";
  models = import ./gateway-models.nix;

  # A recommended model must be in the snapshot, so a gateway rename cannot
  # leave a dangling default in an agent's config.
  requireModel = name:
    if builtins.hasAttr name models
    then name
    else throw "catalog: '${name}' is not in gateway-models.nix (run `just refresh-gateway-models`)";
in
{
  inherit gatewayUrl;

  apiKeyEnv = "JUSPAY_API_KEY";

  # Where the wrappers' prompt sends users to create that key.
  apiKeyUrl = "${gatewayUrl}/dashboard";

  # The models an agent starts on.
  defaultModel = requireModel "glm-latest";
  smallModel = requireModel "open-fast";

  inherit models;
}
