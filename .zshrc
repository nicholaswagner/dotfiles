
# Path to your Oh My Zsh installation.
export ZSH="${HOME}/.oh-my-zsh"

ZSH_THEME="tokyo-sandwich"

plugins=(git tmux zsh-ai nvm bun)

# Oh My Zsh :: Node Version Manager (nvm) plugin configuration
zstyle ':omz:plugins:nvm' autoload yes
zstyle ':omz:plugins:nvm' silent-autoload yes
zstyle ':omz:plugins:nvm' lazy yes

source $ZSH/oh-my-zsh.sh
source "$DOTFILES/.zsh-aliases"
source "$DOTFILES/.zsh-functions"

# uv
export PATH="$HOME/.local/bin:$PATH"
# Adds the LM Studio CLI to the PATH
export PATH="$PATH:$HOME/.lmstudio/bin"
# Rust/Cargo
export PATH="$HOME/.cargo/bin:$PATH"