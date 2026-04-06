# Run recipes from project root, not agents/
set working-directory := '..'

apm_cmd := "nix run github:numtide/llm-agents.nix#apm --"
ai_agent := env('AI_AGENT', 'claude')
# Extract program name (e.g. "claude" from "claude --dangerously-skip-permissions")
apm_target := replace_regex(ai_agent, ' .*', '')

# Deploy APM primitives (rules, commands, skills, hooks)
# --force: without it, apm skips existing files and omits them from the lock
apm:
    {{ apm_cmd }} install --force -t {{ apm_target }}

# Update APM dependencies to latest
update:
    {{ apm_cmd }} install --update --force -t {{ apm_target }}

# Install APM config and launch coding agent (AI_AGENT overrides default)
[default]
run *args: apm
    {{ ai_agent }} {{ args }}
