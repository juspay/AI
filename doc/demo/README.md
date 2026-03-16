# Demo Screencast

Records a GIF of the OpenCode variant selector → oneclick → hello world prompt using [VHS](https://github.com/charmbracelet/vhs).

## Usage

From the repo root:

```bash
export JUSPAY_API_KEY=your-key
just demo
```

This runs `vhs demo.tape` and outputs `demo.gif`, which is linked from the main [README](../../README.md).

## Editing

Modify [`demo.tape`](demo.tape) to change the recording. Key commands:

| Command | Purpose |
|---|---|
| `Type "..."` | Simulate typing |
| `Enter`, `Down` | Key presses |
| `WaitScreen /regex/` | Wait for text to appear |
| `Sleep 5s` | Fixed pause |

See the [VHS docs](https://github.com/charmbracelet/vhs) for the full tape syntax.
