# Oh My Pi demo
# Records a screencast of `nix run .#juspay.omp` → a hello-world prompt answered by the
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
# Tall on purpose. omp's first screen is a stack that has to fit above the input
# box, and at 800px (25 rows) it does not: the welcome panel alone is 20 rows,
# the rotating tip under it is of random length (up to 3 rows), and the
# background update check adds a 5-row "Update Available" banner a few seconds
# in. Anything that does not fit is simply drawn below the bottom of the screen,
# input box included — the recording then sits on the welcome screen, never sees
# the prompt it typed, and times out. 1080px is 34 rows, which covers that
# worst case (20 + 3 + 5 + 3) with room to spare; the slack shows as empty space
# under the input box until the conversation grows into it.
Set Height 1080
Set TypingSpeed 50ms
Set Theme "Catppuccin Mocha"
Set Padding 20
# The reply is an LLM round-trip; give the marker waits room (default is 15s).
Set WaitTimeout 180s

# Pin the pty width to the grid vhs renders (1200px wide at font size 22 with
# padding 20 is 81 columns). The width the shell inherits has come up wrong — 80
# columns against a wider screen — on some runs, and omp lays its welcome screen
# out from that, which is the other way the input box ends up off screen. Only
# the width: pinning rows too leaves a row of the real grid outside the pty, and
# omp's scrolling then strands a stale copy of the status line in it. `Hide`
# keeps the command out of the GIF; `clear` keeps its output out of the frame.
Hide
Type "stty cols 81; clear"
Enter
Sleep 1s
Show

# Type the run command. `nix run .#juspay.omp` rather than `nix run github:juspay/AI#juspay.omp` so the
# recording shows *this* checkout — the published flake would be one release
# behind whatever is being demoed.
Type "nix run .#juspay.omp"
Sleep 500ms
Enter

# The wrapper skips omp's setup wizard (it has already answered everything the
# wizard asks), so the welcome screen is the first thing up. It prints the model
# omp resolved for the `default` role — a gateway id, discovered at startup
# rather than vendored — so it doubles as the "we are on the Juspay gateway"
# marker.
#
# The `default` role is *seeded* into the recording machine's real
# ~/.omp/agent/config.yml on first launch, and never rewritten after that. So
# this wait is only a marker on a machine whose config.yml either does not exist
# yet or still names glm-latest: if you have since switched models with `/model`,
# delete that file before recording or this wait times out on your model's id.
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
