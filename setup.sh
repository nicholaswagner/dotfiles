#!/usr/bin/env bash
set -euo pipefail

# This script bootstraps a new Mac (in theory, i haven't _actually_ tested it yet. YMMV)
# - Oh My Zsh
# - Homebrew and dependencies from Brewfile
# - Node Version Manager (nvm) and latest Node
# - Bun JavaScript runtime
# - Symlinks zsh config files from the dotfiles repo to the home directory

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "[setup] Starting setup with DOTFILES=${DOTFILES}"

# shellcheck source=/dev/null
source "${DOTFILES}/config/zsh/zshenv"

mkdir -p ~/.local/bin

# Initialize git submodules
echo "[git] Initializing submodules..."



# downloads source-maps when websites include them (its a great learning tool)
echo "[git] Initializing source-maps-downloader submodule..."
git -C "${DOTFILES}" submodule update --init submodules/source-maps-downloader
git config -f .gitmodules submodule.submodules/source-maps-downloader.ignore all

# ghostty theme previewer script
echo "[git] Initializing ghostty-themes submodule..."
git -C "${DOTFILES}" submodule update --init submodules/ghostty-themes
git config -f .gitmodules submodule.submodules/ghostty-themes.ignore all
chmod +x submodules/ghostty-themes/ghostty-themes
ln -sf "${DOTFILES}/submodules/ghostty-themes/ghostty-themes" ~/.local/bin/ghostty-themes



# echo "[git] Configuring nerd-fonts sparse checkout..."
# git -C "${DOTFILES}" submodule update --init submodules/nerd-fonts
# git -C "${DOTFILES}/submodules/nerd-fonts" sparse-checkout set \
#   font-patcher \
#   src/glyphs \
#   bin/scripts/name_parser \
#   bin/scripts/braille
# git -C "${DOTFILES}" submodule update submodules/nerd-fonts

# https://ohmyz.sh/#install
if [ ! -d "$HOME/.oh-my-zsh" ]; then
	echo "[oh-my-zsh] Installing..."
	CHSH=yes RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Symlink zsh config files from the dotfiles repo to the home directory.
# Source files have no leading dot; symlink targets in $HOME do.
ZSH_FILES=("zshenv" "zprofile" "zshrc")

for file in "${ZSH_FILES[@]}"; do
	target="$HOME/.$file"
	if [ -f "$target" ] && [ ! -L "$target" ]; then
		echo "[backup] Backing up .${file} to .${file}.bak"
		mv "$target" "${target}.bak"
	fi
	ln -sf "${DOTFILES}/config/zsh/$file" "$target"
	echo "[symlink] Linked ${DOTFILES}/config/zsh/$file to $target"
done

# if the .oh-my-zsh/custom directory already exists, back it up before symlinking
if [ -d "${ZSH}/custom" ] && [ ! -L "${ZSH}/custom" ]; then
	echo "[backup] Backing up existing ${ZSH}/custom to ${ZSH}/custom.bak"
	mv "${ZSH}/custom" "${ZSH}/custom.bak"
fi

# Symlink the custom directory to the dotfiles repo's oh-my-zsh custom directory so we can keep that under version control
ln -sf "${DOTFILES}/config/oh-my-zsh/custom" "${ZSH}/custom"
echo "[symlink] Linked ${DOTFILES}/config/oh-my-zsh/custom to ${ZSH}/custom"

# if no .hushlogin file exists, create one to suppress the "Last login..." message from the terminal
if [ ! -f "$HOME/.hushlogin" ]; then
	touch "$HOME/.hushlogin"
	echo "[hushlogin] Created .hushlogin to suppress last login message"
fi

# https://brew.sh/
if ! command -v brew &> /dev/null; then
	echo "[brew] Installing Homebrew..."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Make brew available in the current session (installer only updates shell config files)
eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || eval "$(/usr/local/bin/brew shellenv)"

echo "[brew] Updating and installing dependencies from Brewfile..."
brew update
brew bundle --file="${DOTFILES}/Brewfile"

# Install huggingface-hub via uv
echo "[uv] Installing huggingface-hub..."
uv tool install "huggingface-hub[hf-xet]"

# Node Version Manager
# https://github.com/nvm-sh/nvm?tab=readme-ov-file#installing-and-updating
if [ ! -d "$HOME/.nvm" ]; then
	echo "[nvm] Installing Node Version Manager..."
	echo "[nvm] [Warning] - This uses a hardcoded version [v0.40.4].  Make sure this is up to date with the latest version from https://github.com/nvm-sh/nvm/releases"
	PROFILE=/dev/null bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash'
fi

# Load nvm and install latest Node
export NVM_DIR="${HOME}/.nvm"
# shellcheck source=/dev/null
[ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh"
nvm install node # "node" is an alias for the latest version

# Install bun via npm (bun also has its own installer, but this is simpler to automate in a script)
npm install -g bun

# Symlink .tmux.conf
if [ -f "$HOME/.tmux.conf" ] && [ ! -L "$HOME/.tmux.conf" ]; then
	echo "[backup] Backing up existing .tmux.conf to .tmux.conf.bak"
	mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak"
fi
ln -sf "${DOTFILES}/config/tmux/tmux.conf" "$HOME/.tmux.conf"
echo "[symlink] Linked ${DOTFILES}/config/tmux/tmux.conf to $HOME/.tmux.conf"

# Symlink ghostty config
# Ghostty on macOS reads from ~/Library/Application Support/com.mitchellh.ghostty/config
# in preference to ~/.config/ghostty/config, so we symlink the Application Support path.
mkdir -p "$HOME/Library/Application Support/com.mitchellh.ghostty"
GHOSTTY_APPSUP_CONFIG="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
if [ -f "$GHOSTTY_APPSUP_CONFIG" ] && [ ! -L "$GHOSTTY_APPSUP_CONFIG" ]; then
	echo "[backup] Backing up existing ghostty Application Support config"
	mv "$GHOSTTY_APPSUP_CONFIG" "${GHOSTTY_APPSUP_CONFIG}.bak"
fi
ln -sf "${DOTFILES}/config/ghostty/ghostty.conf" "$GHOSTTY_APPSUP_CONFIG"
echo "[symlink] Linked ${DOTFILES}/config/ghostty/ghostty.conf to $GHOSTTY_APPSUP_CONFIG"

# NOTE: The ~/.config/ghostty/config symlink below is ignored by Ghostty on macOS
# (Application Support takes precedence). Left commented in case of future need on Linux
# or if Ghostty's config precedence changes.
# mkdir -p "$HOME/.config/ghostty"
# if [ -f "$HOME/.config/ghostty/config" ] && [ ! -L "$HOME/.config/ghostty/config" ]; then
# 	echo "[backup] Backing up existing ghostty config"
# 	mv "$HOME/.config/ghostty/config" "$HOME/.config/ghostty/config.bak"
# fi
# ln -sf "${DOTFILES}/config/ghostty/ghostty.conf" "$HOME/.config/ghostty/config"
# echo "[symlink] Linked ${DOTFILES}/config/ghostty/ghostty.conf to $HOME/.config/ghostty/config"

# Symlink the generated active-theme into Ghostty's themes/ lookup directory.
# Ghostty resolves `theme = active-theme` to <config-dir>/themes/active-theme.
mkdir -p "$HOME/.config/ghostty/themes"
ln -sf "${DOTFILES}/config/ghostty/active-theme" "$HOME/.config/ghostty/themes/active-theme"
echo "[symlink] Linked ${DOTFILES}/config/ghostty/active-theme to $HOME/.config/ghostty/themes/active-theme"

# Symlink .gitconfig
if [ -f "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ]; then
	echo "[backup] Backing up existing .gitconfig to .gitconfig.bak"
	mv "$HOME/.gitconfig" "$HOME/.gitconfig.bak"
fi
ln -sf "${DOTFILES}/config/gitconfig" "$HOME/.gitconfig"
echo "[symlink] Linked ${DOTFILES}/config/gitconfig to $HOME/.gitconfig"

# Symlink neovim config
mkdir -p "$HOME/.config/nvim/colors"
if [ -f "$HOME/.config/nvim/init.lua" ] && [ ! -L "$HOME/.config/nvim/init.lua" ]; then
	echo "[backup] Backing up existing nvim init.lua"
	mv "$HOME/.config/nvim/init.lua" "$HOME/.config/nvim/init.lua.bak"
fi
ln -sf "${DOTFILES}/config/nvim/init.lua" "$HOME/.config/nvim/init.lua"
echo "[symlink] Linked ${DOTFILES}/config/nvim/init.lua to $HOME/.config/nvim/init.lua"
ln -sf "${DOTFILES}/config/nvim/colors/radix.vim" "$HOME/.config/nvim/colors/radix.vim"
echo "[symlink] Linked ${DOTFILES}/config/nvim/colors/radix.vim to $HOME/.config/nvim/colors/radix.vim"
ln -sf "${DOTFILES}/config/nvim/colors/active-theme.lua" "$HOME/.config/nvim/colors/active-theme.lua"
echo "[symlink] Linked ${DOTFILES}/config/nvim/colors/active-theme.lua to $HOME/.config/nvim/colors/active-theme.lua"

python3 "${DOTFILES}/scripts/gen-vim-theme.py"
echo "[vim] Generated colorscheme from current theme"

python3 "${DOTFILES}/scripts/build-ghostty-theme.py"
echo "[ghostty] Generated active-theme from current theme"

uv run "${DOTFILES}/scripts/gen-terminal-icon.py"
echo "[ghostty] Generated Ghostty.icns from current theme"

# Install Nodemon globally
npm install -g nodemon

# Reminder to store the LM Studio API key in the Keychain if it doesn't already exist
if [ -z "$(security find-generic-password -a "$USER" -s "LM_STUDIO_API_KEY" -w 2>/dev/null)" ]; then
	echo ""
	echo "[keychain] ⚠️  LM Studio API key not found in Keychain."
	echo "[keychain] Store it with:"
	echo "[keychain]   security add-generic-password -a \"\$USER\" -s \"LM_STUDIO_API_KEY\" -w \"your-api-key\" -T /usr/bin/security"
fi

echo ""
echo "[done] Setup complete!"
