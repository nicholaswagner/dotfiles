#!/bin/env sh

# Set the default user for the prompt
DEFAULT_USER="$(whoami)"

if [ -z "$DOTFILES" ]; then
  export DOTFILES="${${(%):-%x}:A:h}"
fi

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# LM Studio environment variables
export LM_CONFIG="${DOTFILES}/config/lm_models_config.json"
export LM_ID="google/gemma-4-26b-a4b"
export LM_STUDIO_API_BASE="http://localhost:1234/v1"

# The LM_STUDIO_API_KEY is stored securely in the macOS Keychain and accessed via the `security` command. 
# Make sure to add your API key to the Keychain with the following command:
# security add-generic-password -a "$USER" -s "LM_STUDIO_API_KEY" -w "your_api_key_here"
export LM_STUDIO_API_KEY="$(security find-generic-password -a "$USER" -s "LM_STUDIO_API_KEY" -w 2>/dev/null)"

# These are used by zsh-ai
export ZSH_AI_PROVIDER="openai"
export ZSH_AI_OPENAI_URL="${LM_STUDIO_API_BASE}/chat/completions"
export ZSH_AI_OPENAI_MODEL="${LM_ID}"
export OPENAI_API_KEY="$LM_STUDIO_API_KEY"

# xcode device name for iOS development
export IPHONE_NAME="brick"

# https://bun.com/docs 
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

