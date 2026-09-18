"""Format the update PR from resolved versions; never fetch or change a pin."""
import os
from pathlib import Path


def describe(name, before, after, release_url):
    if before == after:
        return [], f"**{name} unchanged (`{after}`)**"
    return [f"{name} {before} → {after}"], (
        f"**{name} `{before}` → `{after}`**\n\n"
        f"- release notes: {release_url}{after}"
    )


def describe_framework(before, after):
    short_before, short_after = before[:7], after[:7]
    if before == after:
        return [], f"**agent-distro unchanged (`{short_after}`)**"
    return [f"agent-distro {short_before} → {short_after}"], (
        f"**agent-distro `{short_before}` → `{short_after}`**\n\n"
        f"- [compare changes](https://github.com/juspay/agent-distro/compare/{before}...{after})"
    )


def main():
    env = os.environ
    framework_changes, framework_note = describe_framework(
        env["AGENT_DISTRO_BEFORE"], env["AGENT_DISTRO_AFTER"],
    )
    omp_changes, omp_note = describe(
        "oh-my-pi", env["OMP_BEFORE"], env["OMP_AFTER"],
        "https://github.com/can1357/oh-my-pi/releases/tag/",
    )
    codex_changes, codex_note = describe(
        "Codex", env["CODEX_BEFORE"], env["CODEX_AFTER"],
        "https://github.com/openai/codex/releases/tag/rust-v",
    )
    claude_changes, claude_note = describe(
        "Claude Code", env["CLAUDE_BEFORE"], env["CLAUDE_AFTER"],
        "https://github.com/anthropics/claude-code/releases/tag/v",
    )
    changes = framework_changes + omp_changes + codex_changes + claude_changes
    title = "chore(flake): update inputs"
    if changes:
        title += " (" + "; ".join(changes) + ")"
    run_url = f"{env['GITHUB_SERVER_URL']}/{env['GITHUB_REPOSITORY']}/actions/runs/{env['GITHUB_RUN_ID']}"
    temporary = Path(env["RUNNER_TEMP"])
    lock_log = (temporary / "flake-update.log").read_text().rstrip()
    body = temporary / "flake-update-body.md"
    body.write_text(
        "Harness pins follow [agent-distro](https://github.com/juspay/agent-distro); "
        "OMP release selection happens there.\n\n"
        f"Automated flake input update.\n\n{framework_note}\n\n{omp_note}\n\n{codex_note}\n\n{claude_note}\n\n"
        "Codex packaging: https://github.com/sadjow/codex-cli-nix\n\n"
        "Claude Code packaging: https://github.com/sadjow/claude-code-nix\n\n"
        f"```text\n{lock_log}\n```\n\n### CI on this PR\n\n"
        f"The [Update Flake]({run_url}) workflow builds and tests this branch, "
        "then squash-merges the PR only after verification succeeds.\n"
    )
    with Path(env["GITHUB_OUTPUT"]).open("a") as output:
        output.write(f"pr-title={title}\npr-body-path={body}\n")


if __name__ == "__main__":
    main()
