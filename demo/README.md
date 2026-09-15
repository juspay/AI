# Demo Screencast

Records a GIF of `nix run .` → omp's first-run setup → a hello-world prompt answered by the Juspay gateway, using [VHS](https://github.com/charmbracelet/vhs).

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

### The first-run setup wizard

The wrapper gives omp a fresh `PI_CODING_AGENT_DIR` on every run, so every run is
a first run: omp opens its five-step setup wizard before the prompt. The tape
skips it with `Escape`, but never on a timer — each `Escape` is preceded by
`Wait+Screen /Setup step N of 5/`, so a slower machine delays the tape instead of
desynchronising it. Recording without those waits is how keystrokes end up typed
into a provider login form.

## Editing

Modify [`demo.tape`](demo.tape) to change the recording. Key commands:

| Command | Purpose |
|---|---|
| `Type "..."` | Simulate typing |
| `Enter`, `Escape` | Key presses |
| `Wait+Screen /regex/` | Wait for text to appear |
| `Sleep 5s` | Fixed pause |

See the [VHS docs](https://github.com/charmbracelet/vhs) for the full tape syntax.
