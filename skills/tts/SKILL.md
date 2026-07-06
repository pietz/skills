---
name: tts
description: Local text-to-speech via the pocket-tts CLI (Kyutai Pocket TTS). Use when the user wants text spoken aloud ("read this to me", "announce when done") or rendered to an audio file (narration, voiceover), including non-English text (French, German, Spanish, Portuguese, Italian) and cloning a voice from an audio sample.
---

# Text-to-Speech via Pocket TTS

`pocket-tts` (installed at `~/.local/bin/pocket-tts`) wraps Kyutai's Pocket TTS
model. It runs locally on CPU at roughly 9x real-time. Always pass `-q`; the
default logging is noise.

## Speak text aloud

Generate to a temp file, play it, clean up:

```bash
f=$(mktemp /tmp/tts_XXXX.wav) && pocket-tts generate --text "Your message here" -q --output-path "$f" && afplay "$f"; rm -f "$f"
```

The pattern matters: `mktemp` avoids collisions between concurrent calls, and
the final `rm -f` sits behind a semicolon (not `&&`) so the file is removed
even when playback fails or gets interrupted. Don't leave generated audio on
disk unless the user asked for a file.

## Generate an audio file

When the user wants the audio itself, write it where they asked:

```bash
pocket-tts generate --text "Chapter one. It was a bright cold day in April." -q --output-path ~/Desktop/narration.wav
```

Output is always WAV: mono, 24 kHz, 16-bit PCM.

Long texts are fine; the model chunks internally (150 words become ~53 seconds
of audio in ~8 seconds of compute). For multi-page content, generate per
section so progress is visible and a failure doesn't lose everything.

## Voices

Default is `alba` for English; other languages auto-select their own default.
Don't ask the user which voice to use; only pass `--voice` when the request
calls for a specific one.

- Female: `alba` (default), `anna`, `vera`, `fantine`, `eponine`, `azelma`, `mary`, `jane`, `eve`, `cosette`, `caro_davy`
- Male: `jean`, `charles`, `paul`, `george`, `michael`, `marius`, `javert`, `bill_boerst`, `peter_yearsley`, `stuart_bell`
- Language defaults: `estelle` (French), `juergen` (German), `lola` (Spanish), `rafael` (Portuguese), `giovanni` (Italian)

```bash
pocket-tts generate --text "Hello there." --voice paul -q --output-path "$f"
```

## Languages

Pass `--language` for non-English text; it selects the model and default voice:

```bash
pocket-tts generate --text "Guten Morgen, wie geht es dir?" --language german_24l -q --output-path "$f"
```

Available: `english` (default), plus preview models `french_24l`, `german_24l`,
`spanish_24l`, `portuguese_24l`, `italian_24l`. The `_24l` variants are larger
and slower, and first use downloads new weights. Always match the language to
the text; the English model will mangle German.

## Voice cloning (gated)

Two ways to speak in a custom voice from an audio sample (a clean 5-30 second
clip of one speaker works well):

```bash
# One-off: pass the sample directly
pocket-tts generate --text "Hello" --voice /path/to/sample.wav -q --output-path "$f"

# Reusable: export an embedding once, then use it like a voice
pocket-tts export-voice /path/to/sample.wav ~/voices/myvoice.safetensors -q
pocket-tts generate --text "Hello" --voice ~/voices/myvoice.safetensors -q --output-path "$f"
```

Cloning from raw audio is gated: it needs one-time access to the
`kyutai/pocket-tts` model (accept the terms at
https://huggingface.co/kyutai/pocket-tts, then `uvx hf auth login`). The
built-in voice catalog works without it. If a cloning command fails pointing
at that URL, tell the user about the one-time setup instead of retrying.

## Performance

The very first run downloads model weights and can take a minute or two; don't
kill it. After that, each invocation loads cached weights in a few seconds and
generates at ~9x real-time. For many generations in a row (e.g. an audiobook),
`pocket-tts serve` keeps the model warm; for a handful of calls the CLI is
simpler and fast enough.
