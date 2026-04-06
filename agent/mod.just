# Run recipes from project root, not agents/
set working-directory := '..'

apm_cmd := "uvx --from 'git+https://github.com/microsoft/apm' apm"
ai_agent := env('AI_AGENT', 'claude')
# Extract program name (e.g. "claude" from "claude --dangerously-skip-permissions")
apm_target := replace_regex(ai_agent, ' .*', '')

# Deploy APM primitives (rules, commands, skills, hooks)
apm:
    {{ apm_cmd }} install -t {{ apm_target }}

# Install APM config and launch coding agent (AI_AGENT overrides default)
[default]
run *args: apm
    {{ ai_agent }} {{ args }}
