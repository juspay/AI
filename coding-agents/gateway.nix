# Gateway-owned policy, without any agent's provider names or config schema.
# These are recommended aliases, not a model catalog: agents discover models
# from the gateway rather than freezing its capabilities in this repository.
{
  url = "https://grid.ai.juspay.net";
  models = {
    large = "open-large";
    small = "open-fast";
  };
}
