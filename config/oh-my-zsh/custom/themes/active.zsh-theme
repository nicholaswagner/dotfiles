#!/usr/bin/env zsh

# active.zsh-theme
# Author: Nicholas Wagner <github.com/nicholaswagner>

autoload -U colors && colors

# --- ANSI text styles ---
# Wrapped in %{...%} so zsh counts them as zero-width (prevents resize artifacts)
BEGIN_STRIKETHROUGH=$'%{\e[9m%}'
END_STRIKETHROUGH=$'%{\e[29m%}'
BEGIN_UNDERLINE=$'%{\e[4m%}'
END_UNDERLINE=$'%{\e[24m%}'
BEGIN_ITALICS=$'%{\e[3m%}'
END_ITALICS=$'%{\e[23m%}'
BEGIN_BOLD=$'%{\e[1m%}'
END_BOLD=$'%{\e[22m%}'
BEGIN_DIM=$'%{\e[2m%}'
END_DIM=$'%{\e[22m%}'
RESET=$'%{\e[0m%}'
CURRENT_BG="NONE"

prompt_segment() {
  local bg=$1
  local fg=$2
  local content=$3


  if [[ $CURRENT_BG != 'NONE' ]]; then
    print -n "%{%F{$CURRENT_BG}%K{$bg}%}$SEGMENT_SEPARATOR"
  else
    print -n "%{%K{$bg}%}"
  fi

  print -n "%{%F{$fg}%K{$bg}%} $content %F{$bg}%k"
  CURRENT_BG=$bg
}

prompt_end() {
  if [[ $CURRENT_BG != 'NONE' ]]; then
    print -n "%{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{%k%f%}"
  fi
  print -n "%{%k%f%}"
  CURRENT_BG='NONE'
}

# prompt_git() {
#   local ref
#   ref=$(git symbolic-ref --short HEAD 2>/dev/null) || return

#   local dirty git_bg
#   dirty=$(git status --porcelain 2>/dev/null)
#   [[ -n $dirty ]] && git_bg="$THEME_ERROR" || git_bg="$THEME_SUCCESS"

#   local status_str=""
#   ! git diff --cached --quiet 2>/dev/null && status_str+="+"
#   ! git diff --quiet 2>/dev/null && status_str+="!"
#   [[ -n $(git ls-files --others --exclude-standard 2>/dev/null) ]] && status_str+="?"

#   local ahead behind
#   ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null)
#   behind=$(git rev-list --count HEAD..@{u} 2>/dev/null)
#   [[ "$ahead" -gt 0 ]] 2>/dev/null && status_str+="↑${ahead}"
#   [[ "$behind" -gt 0 ]] 2>/dev/null && status_str+="↓${behind}"

#   local label="${ref:u}"
#   [[ -n $status_str ]] && label+=" [$status_str]"

#   prompt_segment "$git_bg" "$THEME_BLACK" "$BRANCH_ICON $label"
# }


prompt_git() {
  local ref dirty

  ref=$(git symbolic-ref --short HEAD 2>/dev/null) || return
  dirty=$(git status --porcelain 2>/dev/null)

  if [[ -n $dirty ]]; then
    prompt_segment "NONE" "$THEME_ERROR_9" " ${BEGIN_ITALICS}$ref${END_ITALICS}"
  else
    prompt_segment "NONE" "$THEME_SUCCESS_9" " ${BEGIN_ITALICS}$ref${END_ITALICS}"
  fi
}

# nothing by default, user@hostname if not default user or ssh
prompt_context() {
  local user=`whoami`
  if [[ -n "$DEFAULT_USER" && "$user" != "$DEFAULT_USER" || -n "$SSH_CONNECTION" ]]; then
    fg="$THEME_ACCENT_12"
    if [[ "$THEME_USE_DARK" == *"accent"* ]]; then
      fg="$THEME_ACCENT_2"
    fi
    prompt_segment "$THEME_ACCENT_9" "$fg" "${BEGIN_ITALICS} $user@%m ${END_ITALICS}"
  fi
}


prompt_status() {
  if [[ $RETVAL -ne 0 ]]; then
      prompt_segment "NONE" "$THEME_ERROR_7" "${BEGIN_ITALICS} $RETVAL${END_ITALICS}"
  fi
}


prompt_dir() {
  prompt_segment "$THEME_ACCENT_2" "$THEME_ACCENT_11" "%~"
}

prompt_nl() {
  printf '\n'
}

# --- Build prompt ---
build_prompt() {
  RETVAL=$?
  prompt_nl
  prompt_context
  prompt_dir
  prompt_status
  prompt_end
  prompt_nl
}

PROMPT='%{%f%b%k%}$(build_prompt) '
