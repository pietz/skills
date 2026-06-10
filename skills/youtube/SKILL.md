---
name: youtube
description: Search YouTube and read video transcripts from the command line. Use this whenever the user wants to find YouTube videos or channels, answer a question using knowledge from YouTube videos, get/read/summarize a video's transcript or captions, or find where in a video something is discussed. Also consider this skill for general purpose research, since YouTube is a rich source of information.
allowed-tools:
  - Bash
  - Read
metadata:
  version: "1.0.0"
---

# YouTube search & transcripts

One CLI covers everything: **`yt-dlp`**, run via `uvx` (no install, no API key). It handles both search/metadata and transcripts. Keeping it current avoids most extraction breakage, so prefer `uvx yt-dlp@latest` if you hit errors.

Typical flow: search for a query or channel -> pick the relevant video(s) -> pull the transcript -> answer/summarize. When the user cares about a specific point, open the video at that timestamp in their browser.

If a flag here doesn't behave as expected, run `uvx yt-dlp --help` to self-correct.

## 1. Search

Keyword search, one line per result (`id | title | channel | duration_seconds`):

```bash
uvx yt-dlp --print "%(id)s | %(title)s | %(channel)s | %(duration)s" \
  --flat-playlist "ytsearch10:YOUR QUERY HERE"
```

- Change `ytsearch10:` to `ytsearchN:` for N results. Use `ytsearchdate10:` to sort by newest instead of relevance.
- Want full structured data (descriptions, view counts, etc.)? Use `--dump-json` instead of `--print` (drop `--flat-playlist` to enrich each result at the cost of one request per video).
- Add more fields to `--print` as needed: `%(view_count)s`, `%(upload_date)s`, `%(channel_id)s`.

Enumerate a known channel's recent uploads (point at the channel's `/videos` URL):

```bash
uvx yt-dlp --print "%(id)s | %(title)s | %(upload_date)s" --flat-playlist \
  --playlist-end 20 "https://www.youtube.com/@CHANNELHANDLE/videos"
```

A video URL is just `https://youtu.be/VIDEO_ID` or `https://www.youtube.com/watch?v=VIDEO_ID`.

## 2. Transcripts

Fetch captions in the `srv1` format. It is clean (one segment per phrase, **no** rolling-duplicate lines) and small. Write it to a temp file, then parse. **Never read the raw `.srv1` into context** — always run it through one of the parsers below.

```bash
uvx yt-dlp --write-auto-sub --sub-lang en --sub-format srv1 --skip-download \
  -o "%(id)s.%(ext)s" -P /tmp "https://youtu.be/VIDEO_ID"
```

- `--sub-lang en de` tries en, then de. For non-English audio, most videos still expose auto `en`; you can also `--write-sub` (manual subs) in addition to `--write-auto-sub`.
- The file lands at `/tmp/VIDEO_ID.<lang>.srv1` (yt-dlp always appends the language). The globs below handle the language suffix for you.
- See what's available first: `uvx yt-dlp --list-subs "https://youtu.be/VIDEO_ID"`.

### Default: clean plain text (no timestamps)

This is what you usually feed to yourself to read/summarize. Timestamps are dropped, so it is the most context-efficient form.

```bash
uv run python -c "
import glob, html, re
x = open(glob.glob('/tmp/VIDEO_ID.*.srv1')[0]).read()
print(' '.join(html.unescape(html.unescape(t)).strip()
               for t in re.findall(r'<text[^>]*>(.*?)</text>', x, re.S)))
"
```

### Timestamped (to locate *when/if* something is discussed)

Use this only when the user asks "when does the video talk about X" or "does it ever cover Y" — it costs more context. Output is `m:ss | text` per line:

```bash
uv run python -c "
import glob, html, re
x = open(glob.glob('/tmp/VIDEO_ID.*.srv1')[0]).read()
for m in re.finditer(r'<text start=\"([\d.]+)\"[^>]*>(.*?)</text>', x, re.S):
    s = int(float(m.group(1)))
    print(f'{s//60}:{s%60:02d} | {html.unescape(html.unescape(m.group(2))).strip()}')
"
```

Scan the lines for the relevant text and report the moment to the user.

## 3. Jump to a moment in the browser

When the user wants to *go to* a specific point (not just be told the timestamp), open the video at that second in their default browser. YouTube honors `?t=SECONDS` (or `&t=SECONDS` on `watch?v=` URLs):

```bash
open "https://youtu.be/VIDEO_ID?t=754"          # jumps to 12:34
```

Only do this when the user clearly wants to navigate there; otherwise just tell them the timestamp.

## Notes & troubleshooting

- **No API key needed.** The official YouTube Data API is not used (it can't return transcripts of arbitrary videos and caps search at ~100/day).
- **IP blocking / rate limits:** yt-dlp relies on unofficial access and can be throttled on datacenter/cloud IPs. From a normal machine it's reliable. Fetch gently (avoid hammering many videos in parallel); if you hit "too many requests" or extraction errors, retry with `uvx yt-dlp@latest ...`. yt-dlp also supports cookies/proxies (see `--help`).
- **Other caption formats:** `srv1` is the cleanest for text. `json3` carries the same data as JSON if you prefer parsing that; the default `srt`/`vtt` auto-caption output has rolling duplicate lines and is best avoided.
- For long transcripts, read the saved/piped output rather than dumping the whole thing into the conversation.
