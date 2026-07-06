---
name: tts
description: Local text-to-speech via the pocket-tts CLI (Kyutai Pocket TTS). Use whenever the user wants text spoken aloud or turned into audio, whether they say "speak", "say this", "read this to me", "announce it", or ask for a voiceover, narration, or .wav file of some text. Also covers multilingual speech (English, French, German, Spanish, Portuguese, Italian) and cloning a voice from an audio sample. Runs fully on-device, no API keys.
---

# Text-to-Speech via Pocket TTS

`pocket-tts` (installed at `~/.local/bin/pocket-tts`) wraps Kyutai's Pocket TTS
model. It runs locally on CPU at roughly 9x real-time, so even a minute of audio
generates in seconds. No internet needed after the first run.

## Speak text aloud

The most common case: generate to a temp file, play it, clean up.

```bash
f=$(mktemp /tmp/tts_XXXX.wav) && pocket-tts generate --text "Your message here" -q --output-path "$f" && afplay "$f"; rm -f "$f"
```

The pattern matters: `mktemp` avoids collisions between concurrent calls, and the
final `rm -f` sits behind a semicolon (not `&&`) so the file is removed even when
playback fails or gets interrupted. Don't leave generated audio on disk unless the
user asked for a file.

## Generate an audio file

When the user wants the audio itself, write it where they asked:

```bash
pocket-tts generate --text "Chapter one. It was a bright cold day in April." -q --output-path ~/Desktop/narration.wav
```

Output is always WAV: mono, 24 kHz, 16-bit PCM. If the user needs mp3 or another
format, convert afterwards (e.g. `ffmpeg -i out.wav out.mp3`).

Long texts are fine. The model chunks internally; a 150-word passage becomes ~53
seconds of audio in under 8 seconds of compute. There is no need to split text
yourself, but for very long content (multiple pages) generate per section so
progress is visible and a failure doesn't lose everything.

## Voices

Built-in voices (no setup needed). Default is `alba` for English; the other
languages auto-select their own default, so only pass `--voice` when the user
wants a specific one.

- Female: `alba` (default), `anna`, `vera`, `fantine`, `eponine`, `azelma`, `mary`, `jane`, `eve`, `cosette`, `caro_davy`
- Male: `jean`, `charles`, `paul`, `george`, `michael`, `marius`, `javert`, `bill_boerst`, `peter_yearsley`, `stuart_bell`
- Language defaults: `estelle` (French), `juergen` (German), `lola` (Spanish), `rafael` (Portuguese), `giovanni` (Italian)

```bash
pocket-tts generate --text "Hello there." --voice paul -q --output-path "$f"
```

Don't ask the user which voice to use. Take the default, or pick one that fits
the request (e.g. a male voice if they ask for one).

## Languages

Pass `--language` for non-English text; it selects the model and default voice:

```bash
pocket-tts generate --text "Guten Morgen, wie geht es dir?" --language german_24l -q --output-path "$f"
```

Available: `english` (default), plus preview models `french_24l`, `german_24l`,
`spanish_24l`, `portuguese_24l`, `italian_24l`. The `_24l` variants are larger
and slower (not yet distilled), so expect the first use to download new weights.
Always match the language to the text; the English model will mangle German.

## Voice cloning

Two ways to speak in a custom voice from an audio sample (a clean 5-30 second
clip of one speaker works well):

```bash
# One-off: pass the sample directly
pocket-tts generate --text "Hello" --voice /path/to/sample.wav -q --output-path "$f"

# Reusable: export an embedding once, then use it like a voice
pocket-tts export-voice /path/to/sample.wav ~/voices/myvoice.safetensors -q
pocket-tts generate --text "Hello" --voice ~/voices/myvoice.safetensors -q --output-path "$f"
```

Cloning from raw audio requires one-time access to the gated model: accept the
terms at https://huggingface.co/kyutai/pocket-tts, then log in locally with
`uvx hf auth login`. Without it, cloning commands fail with a message pointing
at that URL (the built-in voice catalog above still works, since it uses
precomputed embeddings). If cloning fails this way, tell the user about the
one-time setup instead of retrying.

## Performance expectations

- The very first run downloads model weights and can take a minute or two.
  After that, each invocation loads cached weights in a few seconds and then
  generates at ~9x real-time on CPU.
- Always pass `-q` / `--quiet`; the default logging is noisy and useless here.
- For many generations in a row (e.g. an audiobook), per-call model loading
  adds up; `pocket-tts serve` starts a local API that keeps the model warm, but
  for a handful of calls the CLI is simpler and fast enough.
