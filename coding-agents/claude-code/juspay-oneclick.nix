{ pkgs, lib, claude-code, skillsSrc }:
let
  sharedLib = import ../lib.nix;
  skillsDir = pkgs.runCommand "claude-skills" { } ''
    mkdir -p $out/.claude
    ln -s ${skillsSrc}/skills $out/.claude/skills
  '';
in
pkgs.writeShellApplication {
  name = "claude";
  text = ''
    ${sharedLib.checkApiKey}
    export ANTHROPIC_AUTH_TOKEN="''${JUSPAY_API_KEY:-}"
    export ANTHROPIC_BASE_URL="https://grid.ai.juspay.net/"
    export ANTHROPIC_MODEL="glm-latest"
    export ANTHROPIC_SMALL_FAST_MODEL="glm-latest"
    export CLAUDE_CODE_SUBAGENT_MODEL="glm-latest"
    export ANTHROPIC_DEFAULT_SONNET_MODEL="glm-latest"
    export ANTHROPIC_DEFAULT_OPUS_MODEL="glm-latest"
    export ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-latest"
    export DISABLE_INTERLEAVED_THINKING=true
    export API_TIMEOUT_MS=600000
    export BASH_MAX_TIMEOUT_MS=300000
    export CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1
    # Unset conflicting Google/Vertex credentials
    export GEMINI_API_KEY=""
    export GOOGLE_CLOUD_PROJECT=""
    export GOOGLE_APPLICATION_CREDENTIALS=""
    export CLAUDE_CODE_USE_VERTEX=""
    export CLOUD_ML_REGION=""
    export GOOGLE_VERTEX_PROJECT=""
    export ANTHROPIC_VERTEX_PROJECT_ID=""
    exec ${lib.getExe claude-code} --add-dir ${skillsDir} "$@"
  '';
}
