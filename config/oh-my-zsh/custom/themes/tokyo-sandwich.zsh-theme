#!/usr/bin/env zsh

# Tokyo Sandwich Zsh Theme
# A simple, clean, and colorful theme inspired by the Tokyo Night color palette.
# Author: Nicholas Wagner <github.com/nicholaswagner>


# --- Enable colors ---
autoload -U colors && colors

# --- Powerline separator ---
SEGMENT_SEPARATOR=$'\ue0b0' # 

# --- Tokyo Sandwich color palette ---
typeset -A TokyoSandwich
TokyoSandwich[bg]="#1a1b26"
TokyoSandwich[bg_alt]="#292e42"
TokyoSandwich[fg]="#c0caf5"
TokyoSandwich[muted]="#565f89"
TokyoSandwich[blue]="#7aa2f7"
TokyoSandwich[cyan]="#7dcfff"
TokyoSandwich[green]="#9ece6a"
TokyoSandwich[orange]="#ff9e64"
TokyoSandwich[red]="#f7768e"
TokyoSandwich[purple]="#bb9af7"

CURRENT_BG="NONE"

# --- Segment builder ---
prompt_segment() {
  local bg=$1
  local fg=$2
  local content=$3

  if [[ $CURRENT_BG != 'NONE' ]]; then
    print -n "%{%F{$CURRENT_BG}%K{$bg}%}$SEGMENT_SEPARATOR"
  else
    print -n "%{%K{$bg}%}"
  fi

  print -n "%{%F{$fg}%K{$bg}%} $content "
  CURRENT_BG=$bg
}

prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    print -n "%{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  fi
  print -n "%{%f%}"
  CURRENT_BG=""
}

# --- Segments ---

# user@host (only when needed)
prompt_context() {
  if [[ "$USERNAME" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment "$TokyoSandwich[bg_alt]" "$TokyoSandwich[purple]" "%n@%m"
  fi
}

# directory (shortened)
prompt_dir() {
  prompt_segment "$TokyoSandwich[blue]" "$TokyoSandwich[bg]" "%2~"
}

# git (clean + minimal)
prompt_git() {
  local ref dirty

  ref=$(git symbolic-ref --short HEAD 2>/dev/null) || return
  dirty=$(git status --porcelain 2>/dev/null)

  if [[ -n $dirty ]]; then
    prompt_segment "$TokyoSandwich[orange]" "$TokyoSandwich[bg]" " $ref"
  else
    prompt_segment "$TokyoSandwich[green]" "$TokyoSandwich[bg]" " $ref"
  fi
}

# exit status (right side feel, but inline minimal)
prompt_status() {
  if [[ $? -ne 0 ]]; then
    prompt_segment "$TokyoSandwich[red]" "$TokyoSandwich[bg]" "✘"
  fi
}

# --- Build prompt ---
build_prompt() {
  RETVAL=$?

  prompt_context
  prompt_dir
  prompt_git
  prompt_status
  prompt_end
}

PROMPT='%{%f%b%k%}$(build_prompt) '