---
name: tts
description: Local text-to-speech via the pocket-tts CLI. Use when the user wants text spoken aloud, an audio file generated from text, non-English speech such as German/French/Spanish/Portuguese/Italian, a different built-in voice, or voice cloning from an audio sample.
---

# Text-to-Speech

Use `pocket-tts` for local text-to-speech. It is installed at
`~/.local/bin/pocket-tts` and is usually on `PATH`. Pass `-q` to keep logs quiet.

Start with the CLI help when details matter:

```bash
pocket-tts --help
pocket-tts generate --help
pocket-tts export-voice --help
```

## Speak Aloud

Generate into a temporary directory, play it, then remove it:

```bash
d=$(mktemp -d /tmp/tts_XXXXXX) && f="$d/out.wav" && pocket-tts generate --text "Your message here" -q --output-path "$f" && afplay "$f"; rm -rf "$d"
```

Use a temp directory because `pocket-tts` writes WAV output and macOS `mktemp`
does not safely randomize templates like `/tmp/tts_XXXX.wav`.

## Save Audio

When the user asks for a file, write the WAV to the requested path:

```bash
pocket-tts generate --text "Chapter one. It was a bright cold day in April." -q --output-path ~/Desktop/narration.wav
```

Output is WAV: mono, 24 kHz, 16-bit PCM.

## Languages

Use `--language` for non-English text. The English model will pronounce German
and other languages badly.

```bash
pocket-tts generate --text "Guten Morgen, wie geht es dir?" --language german_24l -q --output-path "$f"
```

Useful language values: `english`, `french_24l`, `german_24l`, `spanish_24l`,
`portuguese_24l`, `italian_24l`. The `_24l` models are larger preview models;
first use may take a minute or two while weights download or load.

## Voices

Default English voice is `alba`. Non-English defaults are selected by language:
`estelle` for French, `juergen` for German, `lola` for Spanish, `rafael` for
Portuguese, and `giovanni` for Italian.

Use `--voice` only when the user asks for a specific voice:

```bash
pocket-tts generate --text "Hello there." --voice paul -q --output-path "$f"
```

Examples of built-in voices: `alba`, `anna`, `vera`, `mary`, `jane`, `jean`,
`paul`, `george`, `michael`. Run `pocket-tts generate --help` or try a short
sample if you need to compare options.

## Voice Cloning

For a one-off custom voice from a clean 5-30 second sample:

```bash
pocket-tts generate --text "Hello" --voice /path/to/sample.wav -q --output-path "$f"
```

For reuse:

```bash
pocket-tts export-voice /path/to/sample.wav ~/voices/myvoice.safetensors -q
pocket-tts generate --text "Hello" --voice ~/voices/myvoice.safetensors -q --output-path "$f"
```

Voice cloning can require one-time Hugging Face access to `kyutai/pocket-tts`.
If it fails with a gated-model message, tell the user to accept the model terms
and run `uvx hf auth login`.

## Practical Options

- `--temperature`: adjust variation if the result sounds too flat or unstable.
- `--max-tokens`: change chunk size for longer text if needed.
- `--quantize`: reduce memory usage.
- `pocket-tts serve`: keep the model warm for many generations in a row.
