apm_cmd := "uvx --from 'git+https://github.com/microsoft/apm' apm"

# Deploy APM primitives (rules, commands, skills, hooks)
apm:
    #!/usr/bin/env bash
    set -euo pipefail
    agent="${AI_AGENT:-claude}"
    target="${agent%% *}"
    {{ apm_cmd }} install -t "$target"

# Install APM config and launch coding agent (AI_AGENT overrides default)
[default]
run *args: apm
    {{ env('AI_AGENT', 'claude') }} {{ args }}
