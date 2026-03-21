# Juspay settings for Claude Code.
# Points Claude Code at Juspay's grid.ai LiteLLM proxy.
{
  # Script that provides the API key from JUSPAY_API_KEY env var.
  apiKeyHelper = "echo $JUSPAY_API_KEY";

  env = {
    ANTHROPIC_BASE_URL = "https://grid.ai.juspay.net/";
    DISABLE_INTERLEAVED_THINKING = "true";
    API_TIMEOUT_MS = "600000";
    BASH_MAX_TIMEOUT_MS = "300000";
    CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS = "1";
  };
}
