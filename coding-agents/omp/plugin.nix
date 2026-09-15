# The skill bundle this flake hands its agents, built as an Oh My Pi *plugin*
# package in the store — no vendored copy in the repo.
#
# A plugin is an npm-style package directory: a `package.json` carrying an `omp`
# manifest object, next to the content that manifest points at. OMP's runtime
# skips packages without that manifest, so the manifest is what turns a
# directory of skills into something `extensions:` will load (see
# coding-agents/omp/juspay-oneclick.nix).
#
# The manifest is written fresh here rather than reused from juspay/skills'
# own: this is a *composite* — juspay's skills plus `frontend-design` from
# anthropics/skills and `kolu` from juspay/kolu — so it is a different package
# than any single input, and borrowing an input's name and version would
# misdescribe what is in the tree.
#
# Layout OMP requires: `<root>/skills/<name>/SKILL.md`, exactly one level deep
# and scanned non-recursively. juspay/skills already ships that layout at its
# root, so its skills are copied wholesale; the other two sources contribute one
# skill directory each.
{ lib, runCommand, writeText, fetchgit, juspay-skills, anthropics-skills }:
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
  # lib.fakeHash, and take the hash the build reports.
  #
  # The real fix is upstream — kolu publishing its skill at a path that is not
  # export-ignored, or shipping its own marketplace catalog the way
  # juspay/skills now does. Until then, this is pinned.
  kolu = fetchgit {
    url = "https://github.com/juspay/kolu";
    rev = "1089497577045c7907006e3286e1215d8548b8ce";
    hash = "sha256-TssN2l3kDy8h61oj125dFqpcQm+EvhF8AHPQ/W3atfw=";
    sparseCheckout = [ "agents/.apm/skills/kolu" ];
  };

  manifest = writeText "package.json" (builtins.toJSON {
    name = "juspay-ai-skills";
    version = "1.0.0";
    description = "Skill bundle for the one-click coding agents in juspay/AI";
    license = "MIT";
    # Not published to npm; the store path is the only distribution channel.
    private = true;
    omp.skills = "./skills";
  });
in
runCommand "omp-juspay-skills-plugin" { } ''
  mkdir -p "$out/skills"
  cp -r ${juspay-skills}/skills/. "$out/skills/"
  cp -r ${anthropics-skills}/skills/frontend-design "$out/skills/"
  cp -r ${kolu}/agents/.apm/skills/kolu "$out/skills/"
  chmod -R u+w "$out/skills"
  cp ${manifest} "$out/package.json"

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
