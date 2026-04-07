# Run recipes from project root, not agents/
set working-directory := '..'

apm_cmd := "nix run github:numtide/llm-agents.nix#apm --"
ai_agent := env('AI_AGENT', 'claude')
# Extract program name (e.g. "claude" from "claude --dangerously-skip-permissions")
apm_target := replace_regex(ai_agent, ' .*', '')

# Deploy APM primitives for current agent target
# --force: without it, apm skips existing files and omits them from the lock
apm:
    {{ apm_cmd }} install --force -t {{ apm_target }}

# Regenerate all vendored APM output (.claude/ and .opencode/)
apm-vendor:
    {{ apm_cmd }} install --force -t claude
    {{ apm_cmd }} install --force -t opencode

# Verify vendored dirs match apm lock (for CI)
apm-sync: apm-vendor
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -n "$(git status --porcelain .claude/ .opencode/)" ]; then
        echo "ERROR: vendored APM output out of sync — run: just agent::apm-vendor"
        git status .claude/ .opencode/
        exit 1
    fi

# Update APM dependencies to latest
update:
    {{ apm_cmd }} install --update --force -t {{ apm_target }}

# Install APM config and launch coding agent (AI_AGENT overrides default)
[default]
run *args: apm
    {{ ai_agent }} {{ args }}
