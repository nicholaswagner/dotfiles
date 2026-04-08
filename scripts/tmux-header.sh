#!/usr/bin/env bash

# tmux-header.sh — top status bar for tmux
# Tau Ceti palette - 

TC_acid="#c8ff00"
TC_black="#000000"
TC_muted="#151525"
TC_gray="#4a4a5a"
TC_red="#ff6767"
TC_green="#65f0ad"

# Usage: segment <bg> <fg> <content>
segment() {
  local bg=$1 fg=$2 content=$3
  printf '#[bg=%s,fg=%s] %s #[default]' "$bg" "$fg" "$content"
}

# --- Content ---
user_str="$(echo "$USER" | tr a-z A-Z)"

pane_path=$(tmux display-message -p '#{pane_current_path}' 2>/dev/null)
ref=$(git -C "$pane_path" symbolic-ref --short HEAD 2>/dev/null)
if [[ -n "$ref" ]]; then
  dirty=$(git -C "$pane_path" status --porcelain 2>/dev/null)
  [[ -n "$dirty" ]] && git_bg="$TC_red" || git_bg="$TC_green"
  git_str="$(echo "$ref" | tr a-z A-Z)"
fi

time_str=$(date '+%I:%M:%S %p %Z')

# --- Render ---
printf '#[bold,italics]'
segment "$TC_acid" "$TC_black" "$user_str"
printf '#[nobold,noitalics]'

# right-align git and time
printf '#[push-default,align=right]'
[[ -n "$ref" ]] && segment "$git_bg" "$TC_black" "$git_str"
segment "$TC_muted" "$TC_gray" "$time_str"
printf '#[pop-default]'
