# The skill bundle this flake composes itself, in the store — no vendored copy
# in the repo. The omp wrapper names this directory as an extension root, `omp
# -e <dir>` (see coding-agents/omp/default.nix).
#
# Two sources, and only two: juspay/skills' whole `skills/` tree, plus the one
# `frontend-design` skill out of anthropics/skills. Anything that already ships
# as a standard Agent Plugins package does *not* belong here — kolu used to be
# copied in and is now passed to omp as its own `-e` root, which is what the
# wrapper's second extension is.
#
# The whole contract is the layout: OMP scans `<root>/skills/<name>/SKILL.md`,
# exactly one level deep and non-recursively. `skills` is hardcoded in OMP, not
# read from anywhere, so that directory name is the one thing here that must not
# change. juspay/skills already ships that layout at its root, so its skills are
# copied wholesale; anthropics/skills contributes one skill directory.
#
# Deliberately NOT written here: a `plugin.json` declaring this an Agent Plugins
# package. A bare directory of `skills/` still loads — omp's plugin providers
# scan `skills/` beside every extension root whether or not a manifest names it,
# and the ACP check in coding-agents/test/standalone/test-omp.nix is what would
# go red if a future omp stopped doing that. Giving this bundle a real manifest
# (and with it MCP servers, commands, an `enabled` flag) is juspay/AI#159, not
# this file's business today.
{ runCommand, juspay-skills, anthropics-skills }:

runCommand "omp-juspay-skills-plugin" { } ''
  mkdir -p "$out/skills"
  cp -r ${juspay-skills}/skills/. "$out/skills/"
  cp -r ${anthropics-skills}/skills/frontend-design "$out/skills/"
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
