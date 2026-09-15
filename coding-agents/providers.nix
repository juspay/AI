# The litellm provider block that pi and omp each read out of their models file.
# OMP inherited pi's schema, so the catalog -> entry mapping lives here once; the
# two agents differ only in how they spell the key (pi: `$JUSPAY_API_KEY`, omp:
# the bare name) and in the format they serialize into.
#
# Both agents take a reasoning tier per session (`--model litellm/glm-latest:off
# |low|medium|high|max` for pi), so the catalog's plain gateway ids are all
# either file needs — no per-tier sibling entries like opencode's picker has.
#
# Verified against grid.ai.juspay.net with pi 0.83.0: both the `developer` role
# and the `reasoning_effort` field on reasoning models are accepted, so no
# provider-level `compat` overrides are needed.
let
  catalog = import ./catalog.nix;

  mkModel = name: { context, output, reasoning ? false, ... }: {
    id = name;
    inherit name reasoning;
    input = [ "text" "image" ];
    contextWindow = context;
    maxTokens = output;
  };
in
{ apiKey }:
{
  providers.litellm = {
    baseUrl = catalog.gatewayUrl;
    api = "openai-completions";
    inherit apiKey;
    models = builtins.attrValues (builtins.mapAttrs mkModel catalog.models);
  };
}
