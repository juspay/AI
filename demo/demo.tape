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
# 920, not 800: at 800 the terminal is 25 rows, which omp's welcome screen fills
# to the last row. Its rotating tip line is of random length, and a tip that
# wraps to three lines pushes the input box past the bottom of the screen — the
# recording then sits on the welcome screen, never sees a prompt, and times out.
# The extra rows are the slack that keeps the input box on screen.
Set Height 920
Set TypingSpeed 50ms
Set Theme "Catppuccin Mocha"
Set Padding 20
# The reply is an LLM round-trip; give the marker waits room (default is 15s).
Set WaitTimeout 180s

# Pin the pty to the grid vhs actually renders (1200x920 at font size 22 with
# padding 20 is 28 rows of 81 columns). The size the shell inherits has come up
# wrong — 80 columns against a wider screen — on some runs, and omp lays its
# welcome screen out from that, which is the other way the input box ends up off
# screen. `Hide` keeps the command out of the GIF; `clear` keeps its output out
# of the frame.
Hide
Type "stty rows 28 cols 81; clear"
Enter
Sleep 1s
Show

# Type the run command. `nix run .` rather than `nix run github:juspay/AI` so the
# recording shows *this* checkout — the published flake would be one release
# behind whatever is being demoed.
Type "nix run ."
Sleep 500ms
Enter

# The wrapper skips omp's setup wizard (it has already answered everything the
# wizard asks), so the welcome screen is the first thing up. It prints the model
# omp resolved for the `default` role — a gateway id, discovered at startup
# rather than vendored — so it doubles as the "we are on the Juspay gateway"
# marker.
#
# Match it on the *prompt status line* (`… glm-latest … -4% … 400K`), not on the
# welcome splash, which prints the same id on a line of its own several seconds
# earlier. The splash is not a readiness signal: on a loaded machine omp draws it
# well before the input box exists, and a prompt typed into that gap is dropped
# when omp puts the terminal into raw mode — which is exactly how one recording
# sat on the welcome screen until the ALFABRAVO wait timed out. The trailing
# percentage (context used) only ever appears on the status line, so requiring it
# on the same line waits for the input box instead.
Wait+Screen /glm-latest.*%/
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
# Only submit once the prompt is actually in the input box. If a redraw ate the
# keystrokes this fails here, naming the typing, instead of 180s later at the
# ALFABRAVO wait, which looks like the model never answered. "BRAVO" is a whole
# word, so the input box's word wrapping cannot split it.
Wait+Screen /BRAVO/
Sleep 500ms
Enter

# Wait for the combined marker (only appears in the response)
Wait+Screen /ALFABRAVO/
Sleep 4s

# Exit omp cleanly
Type "/exit"
Enter
Sleep 2s
