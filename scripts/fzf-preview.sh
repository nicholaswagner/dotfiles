#!/usr/bin/env bash
#
# An FZF tmux display-popup preview window script.
# 
# This was originally based on the official example here:
# https://github.com/junegunn/fzf/blob/master/bin/fzf-preview.sh
# 
# I am running Ghostty 1.3.1 and tmux 3.6a.  
# Attempting to use kitty graphics inside a tmux display-popup with
# kitty graphics isn't working for me.  This is my workaround that uses
# symbols / ascii / ansi rendering instead which does.
# 
# Dependencies:
# - https://github.com/sharkdp/bat
# - https://github.com/hpjansson/chafa

if [[ $# -ne 1 ]]; then
  >&2 echo "usage: $0 FILENAME[:LINENO][:IGNORED]"
  exit 1
fi

file=${1/#\~\//$HOME/}

center=0
if [[ ! -r $file ]]; then
  if [[ $file =~ ^(.+):([0-9]+)\ *$ ]] && [[ -r ${BASH_REMATCH[1]} ]]; then
    file=${BASH_REMATCH[1]}
    center=${BASH_REMATCH[2]}
  elif [[ $file =~ ^(.+):([0-9]+):[0-9]+\ *$ ]] && [[ -r ${BASH_REMATCH[1]} ]]; then
    file=${BASH_REMATCH[1]}
    center=${BASH_REMATCH[2]}
  fi
fi

type=$(file --brief --dereference --mime -- "$file")
if [[ ! $type =~ image/ ]]; then
  if [[ $type =~ =binary ]]; then
    file "$1"
    exit
  fi
  bat --style="${BAT_STYLE:-numbers}" --color=always --pager=never --highlight-line="${center:-0}" -- "$file"
  exit
fi

# If tmux preview's widthxheight are unknown, set width and height to terminal width and height
dim=${FZF_PREVIEW_COLUMNS}x${FZF_PREVIEW_LINES}

if [[ $dim == x ]]; then
  dim=$(tput cols 2>/dev/tty)x$(tput lines 2>/dev/tty)
fi

if command -v chafa > /dev/null; then
  chafa --size "$dim" --format symbols --symbols alpha --colors full --fit-width  "$file"  
else
# 4. Cannot find any suitable method to preview the image
  file "$file"
fi
