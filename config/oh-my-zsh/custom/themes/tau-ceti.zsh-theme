#!/usr/bin/env zsh

# tau-ceti.zsh-theme
# Inspired by the Marathon (2025) Explorer UI — Tau Ceti IV map palette
# Author: Nicholas Wagner <github.com/nicholaswagner>

autoload -U colors && colors

# --- Tau Ceti color palette ---
typeset -A TauCeti
TauCeti[bg]="#0a0a14"
TauCeti[bg_alt]="#1a0a2e"
TauCeti[black]="#000000"
TauCeti[fg]="#ffffff"
TauCeti[muted]="#151525"
TauCeti[gray]="#4a4a5a"
TauCeti[acid]="#c8ff00"
TauCeti[lilac]="#aa66ff"
TauCeti[violet]="#6600ff"
TauCeti[red]="#ff6767"
TauCeti[green]="#65f0ad"
TauCeti[orange]="#ff9e64"

# --- Powerline separator ---
SEGMENT_SEPARATOR=$'\ue0b0' # 
BRANCH_ICON=$'\ue0a0' # 

# --- ANSI escape codes for text styles ---
BEGIN_ITALICS=$'\e[3m'
END_ITALICS=$'\e[23m'
BEGIN_BOLD=$'\e[1m'
END_BOLD=$'\e[22m'
BEGIN_DIM=$'\e[2m'
END_DIM=$'\e[22m'
BEGIN_UNDERLINE=$'\e[4m'
END_UNDERLINE=$'\e[24m'
BEGIN_REVERSE=$'\e[7m'
END_REVERSE=$'\e[27m'
BEGIN_STRIKETHROUGH=$'\e[9m'
END_STRIKETHROUGH=$'\e[29m'
BEGIN_INVISIBLE=$'\e[8m'
END_INVISIBLE=$'\e[28m'
BEGIN_RESET=$'\e[0m'




# --- Segment builder ---
prompt_segment() {
  local bg=$1 fg=$2 content=$3
  print -n "%{%K{$bg}%F{$fg}%} $content "
}

prompt_end() {
  print -n "%{%k%f%}"
}

# --- Segments ---

prompt_username() {
  $BEGIN_BOLD $BEGIN_ITALICS $USER $END_ITALICS $END_BOLD
}

prompt_context() {
  if [[ "$USERNAME" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment "$TauCeti[acid]" "$TauCeti[black]" $prompt_username "%n@%m"
  fi
}

# current working directory
prompt_dir() {
  prompt_segment "$TauCeti[muted]" "$TauCeti[gray]" "%~" " "
}

# git branch + status indicators
# prompt_git() {
#   local ref
#   ref=$(git symbolic-ref --short HEAD 2>/dev/null) || return

#   local status_str=""
#   local color="$TauCeti[black]"
#   local bgColor="$TauCeti[green]"

#   if ! git diff --cached --quiet 2>/dev/null; then
#     # Changes staged for commit
#     status_str+="+"
#   fi
#   if ! git diff --quiet 2>/dev/null; then
#     # Changes not staged for commit
#     status_str+="!"
#     color="$TauCeti[black]"
#     bgColor="$TauCeti[red]"
#   fi
#   if [[ -n $(git ls-files --others --exclude-standard 2>/dev/null) ]]; then
#     # Untracked files
#     status_str+="?"
#     # color="$TauCeti[orange]"
#   fi

#   local ahead behind
#   ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null)
#   behind=$(git rev-list --count HEAD..@{u} 2>/dev/null)
#   [[ "$ahead" -gt 0 ]] 2>/dev/null && status_str+="↑${ahead}"
#   [[ "$behind" -gt 0 ]] 2>/dev/null && status_str+="↓${behind}"

#   local label=" ${ref:u} "
#   # [[ -n $status_str ]] && label+=" [$status_str]"

#   prompt_segment "$bgColor" "$color" "$label"
# }
# git (clean + minimal)
# prompt_git() {
#   local ref dirty

#   ref=$(git symbolic-ref --short HEAD 2>/dev/null) || return
#   dirty=$(git status --porcelain 2>/dev/null)

#   if [[ -n $dirty ]]; then
#     prompt_segment "$TauCeti[red]" "$TauCeti[bg]" " $ref "
#   else
#     prompt_segment "$TauCeti[green]" "$TauCeti[bg]" " $ref "
#   fi
#   print -n "%{%k%f%} "
# }

# node version — only shown when .nvmrc or package.json is found in tree
# prompt_node() {
#   local search_dir="$PWD"
#   while [[ "$search_dir" != "/" ]]; do
#     if [[ -f "$search_dir/package.json" || -f "$search_dir/.nvmrc" ]]; then
#       local ver
#       ver=$(node --version 2>/dev/null) || return
#       prompt_segment "$TauCeti[bg_alt]" "$TauCeti[fg]" "⬡ $ver"
#       return
#     fi
#     search_dir="${search_dir:h}"
#   done
# }

# exit status — only shown on non-zero
prompt_status() {
  if [[ $RETVAL -ne 0 ]]; then
    # prompt_segment "$TauCeti[bg]" "$TauCeti[fg]" ""
    print -n "%{%k%f%} "
    prompt_segment "$TauCeti[red]" "$TauCeti[black]" "\uf071 $RETVAL"
  fi
}

# --- Build prompt ---
build_prompt() {
  RETVAL=$?

  prompt_context
  prompt_dir
  # prompt_git
  # prompt_node
  prompt_status
  prompt_end
}

PROMPT='%{%f%b%k%}$(build_prompt) '
# RPROMPT='$(prompt_git)%{%F{#888888}%}%D{%I:%M:%S %p %Z}%{%f%}'
# RPROMPT='%{%F{#888888}%}%D{%I:%M:%S %p %Z}%{%f%}'


PROMPT2='%{%F{#6600ff}%}·%{%f%} '
