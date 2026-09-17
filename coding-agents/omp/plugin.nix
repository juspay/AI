# The skill bundle this flake composes itself, in the store — no vendored copy
# in the repo. The omp wrapper names this directory as an extension root, `omp
# -e <dir>` (see coding-agents/omp/default.nix).
#
# The one source: juspay/skills' whole `skills/` tree. Anything that already
# ships as a standard Agent Plugins package does *not* belong here — kolu used
# to be copied in and is now passed to omp as its own `-e` root, which is what
# the wrapper's second extension is.
#
# The whole contract is the layout: OMP scans `<root>/skills/<name>/SKILL.md`,
# exactly one level deep and non-recursively. `skills` is hardcoded in OMP, not
# read from anywhere, so that directory name is the one thing here that must not
# change. juspay/skills already ships that layout at its root, so its skills are
# copied wholesale.
#
# The root manifest routes discovery through omp's Agent Plugins provider.
# Keep the standard skills layout so other compatible clients can load the
# same bundle. The VM test verifies every bundled skill through a real session.
{ runCommand, juspay-skills }:

runCommand "omp-juspay-skills-plugin" { } ''
  mkdir -p "$out/skills"
  cat > "$out/plugin.json" <<'EOF'
  {
    "$schema": "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json",
    "name": "omp-juspay-skills"
  }
  EOF
  cp -r ${juspay-skills}/skills/. "$out/skills/"
  chmod -R u+w "$out/skills"

  # A skill OMP cannot see is a silent no-op, so fail the build instead: every
  # skill directory must carry the SKILL.md the loader looks for, at exactly the
  # one level down OMP scans.
  for dir in "$out"/skills/*/; do
    if [ ! -f "$dir/SKILL.md" ]; then
      echo "error: $dir has no SKILL.md; OMP would skip it" >&2
      exit 1
    fi
  done
''
