# Portable Agent Plugins bundle. Keep source selection and validation outside
# agent adapters; each adapter decides how its client loads these packages.
# Kolu already ships a complete plugin and is passed through separately.
{ runCommand, juspay-skills }:

runCommand "juspay-skills-plugin" { } ''
  mkdir -p "$out/skills"
  cat > "$out/plugin.json" <<'EOF'
  {
    "$schema": "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json",
    "name": "juspay-skills"
  }
  EOF
  cp -r ${juspay-skills}/skills/. "$out/skills/"
  chmod -R u+w "$out/skills"

  # Every bundled skill must be discoverable at skills/<name>/SKILL.md.
  for dir in "$out"/skills/*/; do
    if [ ! -f "$dir/SKILL.md" ]; then
      echo "error: $dir has no SKILL.md" >&2
      exit 1
    fi
  done
''
