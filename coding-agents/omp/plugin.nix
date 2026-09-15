# The skill bundle this flake hands its agents, composed in the store — no
# vendored copy in the repo. The omp wrapper names this directory under
# `extensions:` (see coding-agents/omp/juspay-oneclick.nix); opencode is handed
# its `skills/` subdirectory.
#
# The whole contract is the layout: OMP scans `<root>/skills/<name>/SKILL.md`,
# exactly one level deep and non-recursively. `skills` is hardcoded in OMP, not
# read from anywhere, so that directory name is the one thing here that must not
# change. juspay/skills already ships that layout at its root, so its skills are
# copied wholesale; the other two sources contribute one skill directory each.
#
# Deliberately NOT written here: a `package.json` with an `omp` manifest. It
# reads like it should be required — OMP's docs describe plugins that way — but
# that requirement belongs to the *installed-plugin* path (`omp plugin install`,
# `~/.omp/plugins/node_modules`), not to `extensions:`. Measured against the omp
# this flake ships, an `extensions:` directory loads its skills identically with
# no package.json at all, with a manifest pointing at a directory that does not
# exist, and with a correct one; and a manifest pointing at real content in a
# directory *not* named `skills` loads nothing. Provider precedence against a
# colliding project skill is unchanged too. So a manifest here would be inert
# code carrying a frozen `version` beside content that changes nightly. If a
# future OMP does start requiring it, the ACP check in
# coding-agents/test/standalone/test-omp-oneclick.nix goes red before the
# nightly lock bump can merge.
{ runCommand, fetchgit, juspay-skills, anthropics-skills }:
let
  # kolu is fetched here rather than declared as a flake input, and that is not
  # a style choice. juspay/kolu's .gitattributes marks `/agents`, `/.agents` and
  # `/.apm` `export-ignore`, and *every* copy of the kolu SKILL.md lives under
  # one of them. Nix's flake fetchers all honour export-ignore — the `github:`
  # tarball by construction, and `git+https` too (verified: both produce the
  # identical narHash, and `?exportIgnore=false` does not change it). So a flake
  # input for kolu would resolve to a tree with no kolu skill in it.
  #
  # `fetchgit` clones and checks out instead, which does not apply
  # export-ignore, and a sparse checkout keeps that from dragging in kolu's
  # ~44MB monorepo. The cost is that this pin is manual: `nix flake update`
  # cannot bump it. To update, change `rev`, set `hash` to
  # the all-zeroes sha256, and take the hash the build reports.
  #
  # The real fix is upstream — kolu publishing its skill at a path that is not
  # export-ignored, or shipping its own marketplace catalog the way
  # juspay/skills now does. Until then, this is pinned.
  # Where the skill sits inside kolu. Named once because the comment above
  # expects it to move: the upstream fix *is* kolu republishing it elsewhere.
  koluSkillPath = "agents/.apm/skills/kolu";
  kolu = fetchgit {
    url = "https://github.com/juspay/kolu";
    rev = "1089497577045c7907006e3286e1215d8548b8ce";
    hash = "sha256-TssN2l3kDy8h61oj125dFqpcQm+EvhF8AHPQ/W3atfw=";
    sparseCheckout = [ koluSkillPath ];
  };
in
runCommand "omp-juspay-skills-plugin" { } ''
  mkdir -p "$out/skills"
  cp -r ${juspay-skills}/skills/. "$out/skills/"
  cp -r ${anthropics-skills}/skills/frontend-design "$out/skills/"
  cp -r ${kolu}/${koluSkillPath} "$out/skills/"
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
