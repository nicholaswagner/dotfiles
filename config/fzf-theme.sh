# fzf-theme.sh
# Requires $DOTFILES/.env to be loaded first (THEME_* vars must be set).
#
# Color slots:
#   fg / fg+         — default text / text of the selected (current) item
#   bg / bg+         — default background / background of the selected item
#   hl / hl+         — matched characters in unselected / selected items
#   info             — the match-count line below the prompt
#   marker           — the symbol shown next to items picked in multi-select mode
#   prompt           — the prompt string itself (e.g. "> ")
#   spinner          — the loading indicator while results stream in
#   pointer          — the cursor arrow pointing at the current item
#   header           — header text (passed via --header or from a command)
#   border           — border lines around the fzf window
#   label            — text in the border label (--border-label)
#   query            — the text you're actively typing in the search box
#
# Layout options:
#   --preview-window — style of the preview pane border
#   --padding        — inner padding inside the fzf window
#   --margin         — outer margin around the fzf window
#   --prompt         — the prompt prefix string
#   --marker         — multi-select indicator character
#   --pointer        — current-item cursor character
#   --separator      — character used to draw the info/header separator line
#   --scrollbar      — character used to draw the scrollbar
#   --info           — where to display the match count ("right", "inline", etc.)
#   --preview-window — "nofollow" stops the preview from auto-scrolling, but doesn't disable maual scroll

export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS
  --color=fg:${THEME_GREY_10},fg+:${THEME_GREY_12},bg:-1,bg+:-1
  --color=hl:${THEME_ACCENT_7},hl+:${THEME_ACCENT_11},info:${THEME_GREY_9},marker:${THEME_SUCCESS_9}
  --color=prompt:${THEME_ACCENT_10},spinner:${THEME_ACCENT_8},pointer:${THEME_ACCENT_9},header:${THEME_GREY_10}
  --color=gutter:-1,border:-1,label:-1,query:-1
  --color=label:${THEME_GREY_9},query:${THEME_GREY_12}
  --preview-window=\"border-rounded\" --padding=\"1\" --margin=\"1\" --prompt=\"󱣱 \"
  --marker=\">\" --pointer=\"\" --separator=\"─\" --scrollbar=\"│\"
  --preview-window=nofollow --info=\"right\""