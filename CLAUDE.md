# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A macOS dotfiles repo (Apple Silicon). The central feature is a **dynamic theme system** that generates consistent color palettes across the terminal (Ghostty), editor (Neovim), shell prompt (zsh), and multiplexer chrome (tmux) from a single source of truth.

## Setup and Install

```bash
./setup.sh          # bootstrap everything: symlinks, brew bundle, theme generation
brew bundle --file=Brewfile   # install/update Homebrew packages (alias: brewfile)
```

`setup.sh` is idempotent — symlinks use `ln -sf`, submodule init is guarded. Safe to re-run.

## Theme System

The pipeline is: **`build-theme` → `.env`** (80+ `THEME_*` vars, repo root) → generator scripts → output files.

`.env` uses dotenv format (`KEY="value"`, no `export`). Shells and tmux load it via `set -a; source "$DOTFILES/.env"; set +a` to auto-export every key. Python generators parse `.env` directly when `THEME_*` isn't already in the environment.

```bash
build-theme --accent violet     # writes .env (--accent locks accent, rest randomizes)
build-theme --stdout            # print to stdout instead of writing
gen-vim-theme                   # writes config/nvim/colors/radix.vim + config/nvim/colors/active-theme.lua
gen-ghostty-theme               # writes config/ghostty/active-theme
gen-terminal-icon               # writes ~/.config/ghostty/Ghostty.icns
```

After `build-theme`, reload the shell or run `set -a; source "$DOTFILES/.env"; set +a` to pick up the new vars in the current session.

**The `THEME_*` variable convention:**

- Six 12-step Radix color scales: `THEME_ACCENT_*`, `THEME_GREY_*`, `THEME_ERROR_*`, `THEME_WARNING_*`, `THEME_SUCCESS_*`, `THEME_INFO_*`
- Step 9 = solid accent (peak chroma); steps 1–2 = backgrounds; steps 11–12 = text
- `THEME_USE_DARK` — space-separated list of roles where step 9 needs dark foreground text (e.g., `accent` when the accent is LIME, YELLOW, etc.)
- `THEME_ACCENT_SCALE_NAME`, `THEME_GREY_SCALE_NAME`, etc. — which Radix scale was chosen
- Meta: `THEME_TYPE` (always `"dark"`)

All color data lives in `config/darkcolors.py` (25 accent scales, 6 grey scales, semantic pools, natural grey pairings).

Generated output files (`active-theme`, `radix.vim`, `active-theme.lua`) are **not committed** — they're regenerated from `.env`.

## Symlink Map

`setup.sh` creates these symlinks:

| Dotfiles path | System path |
|---|---|
| `config/zsh/zshenv` | `~/.zshenv` |
| `config/zsh/zprofile` | `~/.zprofile` |
| `config/zsh/zshrc` | `~/.zshrc` |
| `config/oh-my-zsh/custom/` | `$ZSH/custom/` |
| `config/tmux/tmux.conf` | `~/.tmux.conf` |
| `config/ghostty/ghostty.conf` | `~/.config/ghostty/config` |
| `config/ghostty/active-theme` | `~/.config/ghostty/active-theme` |
| `config/nvim/init.lua` | `~/.config/nvim/init.lua` |
| `config/nvim/colors/radix.vim` | `~/.config/nvim/colors/radix.vim` |
| `config/nvim/colors/active-theme.lua` | `~/.config/nvim/colors/active-theme.lua` |
| `config/gitconfig` | `~/.gitconfig` |

## Shell Config Loading Order

- **`config/zsh/zshenv`** — all shells; sets `$DOTFILES`, `$PATH`, loads `$DOTFILES/.env` (via `set -a; source; set +a`) and `config/fzf-theme.sh`, terminal icon config, LM Studio env vars, API keys from macOS Keychain, zsh-ai provider config
- **`config/zsh/zprofile`** — login shells only; Homebrew init, Obsidian PATH
- **`config/zsh/zshrc`** — interactive shells; Oh My Zsh (plugins: git, tmux, zsh-ai, nvm, bun), sources `config/zsh/aliases.zsh` and `config/zsh/functions.zsh`, `_cmd_rule` preexec hook (draws a colored `─` separator before each command), runs `motd` on startup
- **`config/zsh/aliases.zsh`** — LM Studio shortcuts (`lms-fast/balanced/quality`), `alias cc="claude"`, `alias vim="nvim"`, git log, brew, navigation
- **`config/zsh/functions.zsh`** — Xcode helpers, git safe path, LM Studio loader, ANSI color audit, `get-page-markdown()`, `remap_colors()` (ffmpeg), `window-title()`, OSC 7 directory tracking

## bin/ Scripts

All scripts in `bin/` are on `$PATH` via `config/zsh/zshenv`.

- `build-theme` — Python; generates `$DOTFILES/.env` from Radix scales; supports `--accent #hexcolor` for custom colors, `--stdout` to print instead of writing
- `gen-vim-theme` — Python; reads `THEME_*` vars, writes `config/nvim/colors/radix.vim` (VimScript) + `config/nvim/colors/active-theme.lua` (Lua)
- `gen-ghostty-theme` — Python; writes Ghostty ANSI palette to `config/ghostty/active-theme`
- `gen-terminal-icon` — Python (Pillow via `uv run`); generates `~/.config/ghostty/Ghostty.icns` with gradient, gloss, and text sheen. Configurable via env vars (`TERMINAL_ICON`, `TERMINAL_ICON_CORNER_RADIUS`, etc.)
- `gh-heatmap` — Python; renders a GitHub contribution heatmap in the terminal using `gh api graphql`. Caches viewer data for 24h. Supports `--months`, `--width`, custom colors, and label options
- `motd` — Bash; message-of-the-day shown at shell startup. Composites a `chafa`-rendered avatar image alongside a themed `gh-heatmap`. Skips rendering in VSCode terminals. Uses kitty graphics protocol by default; falls back to `show_tmux_iterm_img` for iTerm2 inside tmux
- `fzf-preview` — Bash; handles image/code previews in fzf using `chafa` (symbols mode) + `bat`
- `build-clip-url` — Bash; compiles `src/ClipURL.swift` → `~/Applications/ClipURL.app` (handles `clip://` URL scheme)
- `show_tmux_iterm_img` — Bash; workaround for rendering chafa images inside tmux via iTerm2 passthrough. Uses DCS double-escaping, Device Status Report (`\033[6n`) handshake to block until the terminal confirms rendering, then pushes the prompt down to avoid overlap

## tmux

The status bar uses two lines (`status 2`): line 1 is the header, line 2 is a thin colored separator.

The tmux server inherits `THEME_*` from the zsh that launches it (zshenv loads `.env`). `tmux.conf` uses inline `run 'tmux set -g ...'` blocks to bake those values into `pane-border-style` and the window-status formats at config load. Status bar scripts read `THEME_*` from the inherited tmux server env on each tick — no file sourcing per second. tmux accepts hex colors directly in style strings (`#[fg=#383a36]`).

- `config/tmux/tmux.conf` — main config: true color, hyperlinks, `status 2`, `status-position top`, `status-interval 1`, `allow-passthrough all` (for Claude Code), mouse on, vim-style pane nav (`C-h/j/k/l`), `prefix + r` to reload, `prefix + k` for fzf file popup. Theme-dependent options (`pane-border-style`, window-status formats) are set via inline `run` blocks that shell-expand `$THEME_*`
- `config/tmux/tmux-header.sh` — status line content: left = user icon + name, right = git branch badge (error/success colored) + time. Uses `segment()` helper that outputs `#[bg=...,fg=...] content #[default]`

## Neovim

Config at `config/nvim/init.lua`. Uses `lazy.nvim` for plugin management. Active colorscheme is `active-theme` (generated Lua file). Plugins: nvim-tree, which-key, tokyonight (fallback), toggleterm, image.nvim (kitty protocol), telescope (+fzf-native), themery (live theme picker), render-markdown.

## Zsh Prompt

Active theme: `config/oh-my-zsh/custom/themes/active.zsh-theme` — powerline-style prompt using `THEME_*` stepped vars. Shows current directory (accent bg), git branch (error/success colored), and exit code on failure. All ANSI escapes wrapped in `%{...%}` for correct zero-width counting.

## Secrets

API keys are stored in macOS Keychain and retrieved in `config/zsh/zshenv` via:

```bash
security find-generic-password -a "$USER" -s "KEY_NAME" -w
```

Currently stored: `LM_STUDIO_API_KEY`, `HUGGING_FACE_TOKEN`. `setup.sh` checks for `LM_STUDIO_API_KEY` and prompts if missing.

## LM Studio

Three profiles per model configured in `config/lm_models_config.json`:

- **fast** — 8K context
- **balanced** — 32K context
- **quality** — 65K context

Models: general (`google/gemma-4-26b-a4b`) and coder (`qwen/qwen3-coder-30b`). Exposed via OpenAI-compatible API at `http://localhost:1234/v1`. The `lms_load()` function in `config/zsh/functions.zsh` loads models by profile name with auto-TTL.

## ClipURL App

`src/ClipURL.swift` + `bin/build-clip-url` create `~/Applications/ClipURL.app`, a background macOS app (no dock icon, `LSUIElement=true`) that handles the `clip://` URL scheme. Used by the Claude Code statusline (`~/.claude/statusline.sh`) so that clicking the session ID hyperlink silently copies the transcript path to the clipboard.
