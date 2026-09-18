#!/usr/bin/env bash
# Read the resolved framework pin and harness versions without changing inputs.
set -euo pipefail

omp_version=$(jq -er '.nodes as $nodes | $nodes[$nodes.root.inputs["agent-distro"]].inputs["oh-my-pi"] as $omp | $nodes[$omp].original.ref' flake.lock)
codex_version=$(nix eval --raw .#codex.version)
claude_version=$(nix eval --raw .#claude.version)
agent_distro_rev=$(jq -er '.nodes as $nodes | $nodes[$nodes.root.inputs["agent-distro"]].locked.rev' flake.lock)

{
  printf 'omp-version=%s\n' "$omp_version"
  printf 'codex-version=%s\n' "$codex_version"
  printf 'claude-version=%s\n' "$claude_version"
  printf 'agent-distro-rev=%s\n' "$agent_distro_rev"
} >> "$GITHUB_OUTPUT"
