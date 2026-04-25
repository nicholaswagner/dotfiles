#!/usr/bin/env bash

# LM Studio Aliases -------------------------------------
alias lms-fast="lms load \${LM_ID} --gpu max -c 8192 --identifier lm-fast"
alias lms-balanced="lms load \${LM_ID} --gpu max -c 32768 --identifier lm-balanced"
alias lms-quality="lms load \${LM_ID} --gpu max -c 65536 --identifier lm-quality"

alias lms-coder-fast="lms load \${LM_CODER_ID} --gpu max -c 8192 --identifier lm-coder-fast"
alias lms-coder-balanced="lms load \${LM_CODER_ID} --gpu max -c 32768 --identifier lm-coder-balanced"
alias lms-coder-quality="lms load \${LM_CODER_ID} --gpu max -c 65536 --identifier lm-coder-quality"

# Claude Code
alias cc="claude"
alias vim="nvim"
# Git Aliases -------------------------------------
alias git-log="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)' --all"

# Brew -------------------------------------
alias brewfile="brew bundle --file=\${DOTFILES}/Brewfile"

# CLI Tools -------------------------------------
alias readme="glow ./README.md"
alias source-maps="node \${DOTFILES}/submodules/source-maps-downloader/index.js"

# Navigation -------------------------------------
alias dotfiles="cd \${DOTFILES}"
alias repos="cd ~/repos"
alias nw="cd ~/repos/dev.nicholaswagner"
alias vault='\${HOME}/Library/Mobile\ Documents/iCloud~md~obsidian/Documents'

# web reference pages
alias tmux-cheatsheet='open -a Google\ Chrome https://tmuxcheatsheet.com'

alias ghhtml='ghostty-html <<< "$(pbpaste)"'