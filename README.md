# Skills

A collection of reusable skills for AI coding agents like Claude Code, Codex, and Gemini CLI.

## Install

```bash
# All skills
npx skills add pietz/skills

# Individual skill
npx skills add pietz/skills/skills/calendar
```

## Available Skills

| Skill | Description |
|---|---|
| **calendar** | Calendar management via macOS Calendar.app |
| **email** | Email operations via macOS Mail.app |
| **m365** | Microsoft 365 email & calendar via CLI for Microsoft 365 |
| **slides** | Create presentations, flyers, and posters via HTML/CSS to PDF |
| **railway** | Deploy and manage apps on Railway |
| **peer-review** | Get alternative perspectives from other LLMs |
| **ship** | Test, validate, fresh-eyes review, then commit and push to main |
| **tts** | Local text-to-speech via the pocket-tts CLI: speak aloud, generate audio files, clone voices |

## Local Setup

If you want to symlink skills into your agent's skill directory:

```bash
scripts/link-skills.sh         # dry run
scripts/link-skills.sh --apply # apply safe symlinks
```
