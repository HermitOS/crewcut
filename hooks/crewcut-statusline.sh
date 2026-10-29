#!/usr/bin/env bash
# CLAUDE_CONFIG_DIR overrides ~/.claude, matching where the hooks write the flag (issue #34)
flag="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.crewcut-active"
# A symlinked flag could point the statusline at any file; ignore it.
[ -f "$flag" ] && [ ! -L "$flag" ] || exit 0

# Keep only a-z0-9- from the first 64 bytes: the flag is printed to the
# terminal, so stray bytes there must never become escape sequences.
mode=$(head -c 64 "$flag" | head -n1 | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9-')

# ultra is the high-intensity mode; flag it amber so it stands out from the
# default green at a glance. The level is still in the text, so color is a
# redundant cue, not the only one.
color=108
[ "$mode" = "ultra" ] && color=173

if [ -z "$mode" ] || [ "$mode" = "full" ]; then
    printf '\033[38;5;%sm[CREWCUT]\033[0m' "$color"
else
    printf '\033[38;5;%sm[CREWCUT:%s]\033[0m' "$color" "$(printf '%s' "$mode" | tr '[:lower:]' '[:upper:]')"
fi
