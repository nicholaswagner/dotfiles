#!/usr/bin/env zsh


: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# early return when inside vscode
if [ "$TERM_PROGRAM" = "vscode" ]; then
    return 0 2>/dev/null || exit 0
fi


function hr() {
    echo
    printf '─%.0s' {1..$COLUMNS}
    echo
}

function show-my-face() {
    local args=(
        "${DOTFILES}/assets/avatar__256x256.png"
        --size="20x20"
        --fit-width
        --margin-bottom=1
    )

    if [[ "$HOST_TERM_PROGRAM" == "iTerm.app" ]]; then
        args+=("--format=iterm")
    elif [[ $HOST_TERM_PROGRAM == "Apple_Terminal" ]]; then
        args+=("--format=symbols")
        args+=("--symbols=ascii")
    else
        args+=("--format=kitty")
    fi

    if [[ "$TERM_PROGRAM" == "tmux" ]]; then
        args+=("--passthrough=tmux")
    fi

    if [[ "$HOST_TERM_PROGRAM" == "iTerm.app" && -n "$TMUX" ]]; then
        show_tmux_iterm_img "${args[@]}"
    else
        chafa "${args[@]}"
    fi
}

# early return when inside tmux, but only if not in the first pane
if [ -n "$TMUX_PANE" ] && [ "$TMUX_PANE" != "%0" ]; then
    return 0 2>/dev/null || exit 0
fi


# indent=""
# heatmap_width=$((TMUX_PANE_WIDTH - 20))
indent=$(printf '%*s' $((20)) '')
heatmap_width=$((COLUMNS - 20))
heatmap=$(uvx --from heatgraph heatgraph-helpers gh-contributions --from 2026-01-01 --pad-to-width --direction rtl --max-columns=$heatmap_width --message "" --no-invert-headers)
n=$(printf '%s\n' "$heatmap" | wc -l | tr -d ' ')
printf '%s\n' "$heatmap" | sed "s/^/$indent/"

# Move cursor back up to the start of the block
printf '\033[%dA' "$(($n + 1))"
show-my-face
hr
lms ps

