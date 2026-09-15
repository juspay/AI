# Oh My Pi demo
# Records a screencast of `nix run .` → a hello-world prompt answered by the
# Juspay gateway's default model.
#
# Usage (from the repo root):
#   export LITELLM_API_KEY=your-gateway-key
#   just demo
#
# The key is read from the environment vhs inherits — never typed on screen, so
# it cannot end up in the GIF.

Output demo.gif

Require nix

Set Shell "bash"
# Provided through fontconfig by demo/flake.nix; the recording machines have no
# monospace font of their own.
Set FontFamily "JetBrains Mono"
Set FontSize 22
Set Width 1200
Set Height 800
Set TypingSpeed 50ms
Set Theme "Catppuccin Mocha"
Set Padding 20
# The reply is an LLM round-trip; give the marker waits room (default is 15s).
Set WaitTimeout 180s

# Type the run command. `nix run .` rather than `nix run github:juspay/AI` so the
# recording shows *this* checkout — the published flake would be one release
# behind whatever is being demoed.
Type "nix run ."
Sleep 500ms
Enter

# The wrapper skips omp's setup wizard (it has already answered everything the
# wizard asks), so the welcome screen is the first thing up. Its status line
# carries the model omp resolved for the `default` role — a gateway id,
# discovered at startup rather than vendored — so it doubles as the "we are on
# the Juspay gateway" marker.
Wait+Screen /glm-latest/
# omp checks for updates in the background after the welcome screen and redraws
# when the "Update Available" banner lands; keystrokes typed across that redraw
# were lost on a recording machine. Let it settle before typing.
Sleep 8s

# A hello-world prompt that needs no tools, so nothing stops for an approval.
# Trick: ask the LLM to concatenate two words (ALFA+BRAVO) and print the result.
# The prompt contains "ALFA" and "BRAVO" separately, but never "ALFABRAVO" as
# one string — so Wait+Screen only matches when the LLM outputs the combined
# form. See demo/README.md.
Type "In one sentence, say what Oh My Pi is. Then print ALFA concatenated with BRAVO."
Sleep 500ms
Enter

# Wait for the combined marker (only appears in the response)
Wait+Screen /ALFABRAVO/
Sleep 4s

# Exit omp cleanly
Type "/exit"
Enter
Sleep 2s
