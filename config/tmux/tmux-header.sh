#!/usr/bin/env bash
# Usage: tmux-header.sh left|right
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

eval "$(tmux show-environment -g | grep '^THEME_')"

segment() {
  local bg=$1 fg=$2 content=$3
  printf '#[bg=%s,fg=%s] %s #[default]' "$bg" "$fg" "$content"
}

case "${1:-}" in
  left)
    user_str="${TERMINAL_ICON}  ${USER}      "
    printf '#[italics]'
    segment "NONE" "$THEME_GREY_6" " $user_str"
    printf '#[nobold,noitalics]'
    ;;

  right)
    pane_path=$(tmux display-message -p '#{pane_current_path}' 2>/dev/null)
    ref=$(git -C "$pane_path" symbolic-ref --short HEAD 2>/dev/null)

    if [[ -n "$ref" ]]; then
      dirty=$(git -C "$pane_path" status --porcelain 2>/dev/null)
      if [[ -n "$dirty" ]]; then
        git_bg="$THEME_ERROR_5"
        git_fg="$THEME_ERROR_11"
      else
        git_bg="$THEME_SUCCESS_9"
        [[ "$THEME_USE_DARK" == *"success"* ]] && git_fg="$THEME_SUCCESS_1" || git_fg="$THEME_SUCCESS_12"
      fi
      segment "$git_bg" "$git_fg" " #[italics]  #${ref}#[noitalics] "
    fi

    time_str=$(date '+%I:%M:%S %p %Z')
    segment "$THEME_GREY_1" "$THEME_ACCENT_11" "$time_str"
    ;;
esac
