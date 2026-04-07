#!/usr/bin/env zsh

# Set up Homebrew in the shell environment
eval "$(/opt/homebrew/bin/brew shellenv)"

# Dotfiles scripts
export PATH="${DOTFILES}/scripts:$PATH"
