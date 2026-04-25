#!/usr/bin/env bash

# early return when inside vscode
if [ "$TERM_PROGRAM" = "vscode" ]; then
    return 0 2>/dev/null || exit 0
fi

args=(
    --size="20x20"
    --fit-width
    "$@"
)

# Handle iTerm, default apple terminal, and ghostty
if [[ "$HOST_TERM_PROGRAM" == "iTerm.app" ]]; then
    args+=("--format=iterm")
elif [[ $HOST_TERM_PROGRAM == "Apple_Terminal" ]]; then
    args+=("--format=symbols")
    args+=("--symbols=ascii")
else
    args+=("--format=kitty")
fi

# When viewing in tmux you need to use the passthrough (its not always detected)
if [[ "$TERM_PROGRAM" == "tmux" ]]; then
    args+=("--passthrough=tmux")
fi

# iterm + tmux requires a hacky workaround
if [[ "$HOST_TERM_PROGRAM" == "iTerm.app" && -n "$TMUX" ]]; then
    show_tmux_iterm_img "${args[@]}"
else
    chafa "${args[@]}"
fi