# Run recipes from project root, not agents/
set working-directory := '..'

apm_cmd := "uvx --from git+https://github.com/microsoft/apm@v0.8.10 apm"
ai_agent := env('AI_AGENT', 'claude')

# Regenerate vendored APM output (.claude/ and .opencode/) from scratch
# Lock file deleted between targets to work around hash mismatch (#529)
apm-vendor:
    rm -rf .claude/ .opencode/ apm.lock.yaml
    {{ apm_cmd }} install --force -t claude
    rm -f apm.lock.yaml
    {{ apm_cmd }} install --force -t opencode

# Update APM dependencies to latest, then re-vendor
update: && apm-vendor
    {{ apm_cmd }} install --update --force -t claude

# Launch coding agent (AI_AGENT overrides default)
[default]
run *args:
    {{ ai_agent }} {{ args }}
