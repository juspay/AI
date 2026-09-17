#!/usr/bin/env bash
# OMP's release policy: tags move only forward, even if publishing a release lags.
set -euo pipefail

before=$(sed -n 's|.*oh-my-pi\.url = "github:can1357/oh-my-pi/\([^"]*\)";.*|\1|p' flake.nix)
latest=$(gh release view --repo can1357/oh-my-pi --json tagName --jq .tagName)
for version in "$before" "$latest"; do
  if [[ ! "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "error: unusable oh-my-pi release tag: $version" >&2
    exit 1
  fi
done

after="$before"
if [ "$before" != "$latest" ] && [ "$(printf '%s\n' "$before" "$latest" | sort -V | tail -n1)" = "$latest" ]; then
  after="$latest"
  sed -i "s|github:can1357/oh-my-pi/$before|github:can1357/oh-my-pi/$after|" flake.nix
  grep -qF "oh-my-pi.url = \"github:can1357/oh-my-pi/$after\";" flake.nix
fi

# Facts only. PR wording belongs to describe-flake-update.py.
{
  echo "before=$before"
  echo "after=$after"
  echo "latest=$latest"
} >> "$GITHUB_OUTPUT"
