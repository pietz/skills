#!/usr/bin/env bash
set -euo pipefail

# Link skills from this repo into the installed agent skill directories.
# This keeps a single editable source of truth in this repo while preserving
# agent-native directories (e.g. Codex .system, Gemini built-ins/extensions).
#
# Usage:
#   scripts/link-skills.sh            # dry run
#   scripts/link-skills.sh --apply    # apply changes
#   scripts/link-skills.sh --apply --agent claude --agent codex
#
# Conflict policy:
# - If the target path does not exist: create symlink.
# - If it is already a symlink to the repo skill: do nothing.
# - If it exists and differs from the repo skill: report conflict and skip.
# - If it exists and is identical to the repo skill: replace with symlink.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repo_skills_dir="${repo_root}/skills"

apply=false
agents=()
skills=()

usage() {
  cat <<'EOF'
Usage: scripts/link-skills.sh [--apply] [--agent <claude|codex|gemini>]... [--skill <name>]...

Defaults:
  - agents: claude, codex, gemini
  - skills: all directories under ./skills

Notes:
  - This script is intentionally conservative: it will not overwrite differing
    skills; it reports conflicts instead.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --apply) apply=true; shift ;;
    --agent) agents+=("${2:-}"); shift 2 ;;
    --skill) skills+=("${2:-}"); shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "Unknown arg: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ ${#agents[@]} -eq 0 ]; then
  agents=(claude codex gemini)
fi

if [ ${#skills[@]} -eq 0 ]; then
  while IFS= read -r -d '' d; do
    skills+=("$(basename "$d")")
  done < <(find "$repo_skills_dir" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
fi

agent_dir_for() {
  case "$1" in
    claude) echo "${HOME}/.claude/skills" ;;
    codex) echo "${HOME}/.codex/skills" ;;
    gemini) echo "${HOME}/.gemini/skills" ;;
    *)
      echo "Unknown agent: $1" >&2
      exit 2
      ;;
  esac
}

is_same_dir() {
  # Compare directories recursively, ignoring macOS metadata files.
  # Returns 0 if identical, 1 otherwise.
  local a="$1"
  local b="$2"
  diff -qr \
    -x '.DS_Store' \
    -x '__MACOSX' \
    -x '__pycache__' \
    -x '*.pyc' \
    "$a" "$b" >/dev/null 2>&1
}

shorten() {
  local p="$1"
  echo "${p/#$HOME/~}"
}

actions=()
conflicts=()
skipped_missing=()

for agent in "${agents[@]}"; do
  target_root="$(agent_dir_for "$agent")"
  if [ "$apply" = true ]; then
    mkdir -p "$target_root"
  fi

  for skill in "${skills[@]}"; do
    src="${repo_skills_dir}/${skill}"
    dst="${target_root}/${skill}"

    if [ ! -d "$src" ]; then
      skipped_missing+=("${agent}:${skill} (missing in repo)")
      continue
    fi

    if [ ! -e "$dst" ] && [ ! -L "$dst" ]; then
      actions+=("link ${agent}: $(shorten "$dst") -> $(shorten "$src")")
      if [ "$apply" = true ]; then
        ln -s "$src" "$dst"
      fi
      continue
    fi

    if [ -L "$dst" ]; then
      # Existing symlink: check where it points.
      link_target="$(readlink "$dst" || true)"
      dst_real="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$dst" 2>/dev/null || true)"
      src_real="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$src" 2>/dev/null || true)"
      if [ -n "${dst_real:-}" ] && [ -n "${src_real:-}" ] && [ "$dst_real" = "$src_real" ]; then
        actions+=("ok   ${agent}: $(shorten "$dst") already linked")
      else
        conflicts+=("${agent}:${skill} (symlink points elsewhere: ${link_target})")
      fi
      continue
    fi

    # Existing non-symlink. Only replace if identical.
    if [ -d "$dst" ]; then
      if is_same_dir "$src" "$dst"; then
        actions+=("relink ${agent}: $(shorten "$dst") (identical, replace with symlink)")
        if [ "$apply" = true ]; then
          rm -rf -- "$dst"
          ln -s "$src" "$dst"
        fi
      else
        conflicts+=("${agent}:${skill} (differs; leaving existing at $(shorten "$dst"))")
      fi
    else
      conflicts+=("${agent}:${skill} (exists but is not a directory/symlink: $(shorten "$dst"))")
    fi
  done
done

echo "Repo skills dir: $(shorten "$repo_skills_dir")"
echo "Mode: $([ "$apply" = true ] && echo apply || echo dry-run)"
echo

if [ ${#actions[@]} -gt 0 ]; then
  echo "Actions:"
  for a in "${actions[@]}"; do
    echo "  - $a"
  done
  echo
fi

if [ ${#conflicts[@]} -gt 0 ]; then
  echo "Conflicts (manual merge needed):"
  for c in "${conflicts[@]}"; do
    echo "  - $c"
  done
  echo
fi

if [ ${#skipped_missing[@]} -gt 0 ]; then
  echo "Skipped:"
  for s in "${skipped_missing[@]}"; do
    echo "  - $s"
  done
  echo
fi

if [ "$apply" = false ]; then
  echo "Next: re-run with --apply to create/replace symlinks where safe."
fi
