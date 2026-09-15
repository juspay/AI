# Demo Screencast

Records a GIF of `nix run .` → a hello-world prompt answered by the Juspay gateway, using [VHS](https://github.com/charmbracelet/vhs).

## Usage

From the repo root:

```bash
export LITELLM_API_KEY=your-gateway-key
just demo
```

This runs `vhs demo/demo.tape` and outputs `demo.gif`, which is linked from the main [README](../README.md). The key is only ever read from the environment, so it never appears in the recording.

## How it works

### The concatenation marker trick

The hardest part of recording an LLM-powered TUI is knowing when the response is **done**. VHS can detect text appearing on screen (`Wait+Screen`), but *not* text disappearing. Here's what doesn't work:

| Approach | Why it fails |
|---|---|
| **Fixed `Sleep`** | Not deterministic — too short cuts off the response, too long wastes time |
| **Unique marker in prompt** (e.g., `XYZENDXYZ`) | The marker appears in the typed prompt text on screen, so `Wait+Screen` matches immediately |
| **Math formula** (e.g., `347+829` → wait for `1176`) | The LLM computes the answer in its visible *thinking trace* before the response finishes |
| **`Wait+Line /^MARKER$/`** | TUI padding/borders prevent exact line matching |

**What works: the concatenation trick.** We ask the LLM to print the concatenation of two words (e.g., `ALFA` + `BRAVO`). The prompt contains both words *separately* but never the combined string `ALFABRAVO`. The thinking trace discusses them individually ("I need to concatenate ALFA and BRAVO") but doesn't produce the combined form. Only the final response outputs `ALFABRAVO` — giving us a reliable, deterministic `Wait+Screen` marker.

```
# In the tape:
Type "briefly explain this repo. Then print ALFA concatenated with BRAVO."
Enter
Wait+Screen /ALFABRAVO/
```

### Waiting for the input box, then settling

The wrapper skips omp's setup wizard (`OMP_SKIP_SETUP=1`; it has already
configured provider, key and model), so the welcome screen is the first thing
up. The welcome *splash* is not a readiness marker, though: it prints the model
id seconds before the input box exists, and on a loaded machine a prompt typed
into that gap is dropped when omp switches the terminal to raw mode — the
recording then sits on the welcome screen until the `ALFABRAVO` wait times out.
So the tape waits for `/glm-latest.*%/`, which only matches the prompt status
line (model id and context-used percentage on one line), not the splash.

omp then checks for updates in the background and redraws when the "Update
Available" banner lands; keystrokes typed across that redraw were lost on a
recording machine, so the tape sleeps a few seconds after the marker before
typing the prompt, and waits for `/BRAVO/` — part of the typed text — before
pressing Enter, so lost keystrokes fail at the typing rather than at the
response wait.

### Fonts

vhs renders through its bundled chromium, which takes fonts from fontconfig.
The recording machines ship a single proportional font, so the demo flake
points `FONTCONFIG_FILE` at a JetBrains Mono fontconfig and the tape selects
that family.

## Editing

Modify [`demo.tape`](demo.tape) to change the recording. Key commands:

| Command | Purpose |
|---|---|
| `Type "..."` | Simulate typing |
| `Enter`, `Escape` | Key presses |
| `Wait+Screen /regex/` | Wait for text to appear |
| `Sleep 5s` | Fixed pause |

See the [VHS docs](https://github.com/charmbracelet/vhs) for the full tape syntax.
