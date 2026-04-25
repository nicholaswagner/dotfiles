# ~/dotfiles

![A screenshot of a terminal with a custom theme](assets/tokyosandwich.png)

My personal dotfiles collection for macOS (Apple Silicon).  
I've had Claude make an effort to summerize what's going on in here, but YMMV.

At the moment i'm playing around with a terminal theme engine heavily ~~stolen~~ inspired by the radix-ui team.

---
> [!NOTE]
> I previously had this doing a sparse checkout on the nerd-fonts repo so I could quickly patch together a custom `DankMono` Nerd Font with some additional custom glyphs, but that project is huge, and its something I do maybe once every couple of years, so i've currently got it commented out.  (BTW - If you're not using [DankMono](https://philpl.gumroad.com/l/dank-mono) you really should be.)

---

> [!IMPORTANT]
> Theming is still a hacked together PoC.  Currently its `darkmode` only, and you can either have it build you a random radix-ui/colors inspired color palette, or you can give it an accent color (it assumes accent_9) and it will generate the palette + grey scales for you. It generates a zsh theme + nvim theme + ghostty app icon that includes whatever nerdy mark you've currently got set in the `zshenv` file. 

---

> [!TIP]
> There's a bug with trying to display kitty / iTerm graphics inside `tmux` when you use `iTerm.app`.  I'm honestly still not entirely sure what the _true_ root cause of that is, but if anyone stumbles across this while trying to get their setup working, you might find the `bin/show_tmux_iterm_img` script useful.



## Requirements

- macOS (Apple Silicon)
- git (available by default via Xcode Command Line Tools)
- `zsh`
- `ghostty` or `iterm` terminal
- a "nerdy" font that has the powerline + nerd glyphs
- be some kind of awful masochist? I dunno.

## Quick start

```bash
git clone https://github.com/nicholaswagner/dotfiles 
cd dotfiles && ./setup.sh
```

`setup.sh` _should be_ idempotent -- symlinks use `ln -sf`, submodule init is guarded. Safe to re-run.

## What it sets up

| Tool | Description |
| ---- | ----------- |
| [Oh My Zsh](https://ohmyz.sh) | Zsh framework with plugins and themes |
| [Homebrew](https://brew.sh) | Package manager -- installs everything in `Brewfile` |
| [Ghostty](https://ghostty.org) | GPU-accelerated terminal with true color and image support |
| [Neovim](https://neovim.io) | Editor with lazy.nvim plugin management and generated colorscheme |
| [tmux](https://github.com/tmux/tmux) | Terminal multiplexer with themed two-line status bar |
| [nvm](https://github.com/nvm-sh/nvm) | Node Version Manager + latest Node |
| [bun](https://bun.sh) | JavaScript runtime |
| [LM Studio](https://lmstudio.ai) | Local LLM inference via OpenAI-compatible API |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder with themed colors and image previews |
| [chafa](https://hpjansson.org/chafa/) | Terminal image rendering (used by `motd` and `fzf-preview`) |

## Theme system

The pipeline: **`build-theme` --> `.env`** (80+ `THEME_*` vars) --> generator scripts --> output files.

Built on [Radix UI color scales](https://www.radix-ui.com/colors) -- 25 accent scales, 6 grey scales, semantic pools for error/warning/success/info, and natural grey pairings. Each scale has 12 steps with defined roles (backgrounds, borders, solids, text).

```bash
build-theme                     # fully random palette
build-theme --accent violet     # lock accent, randomize the rest
build-theme --accent '#8e4ec6'  # custom hex color with generated 12-step scale
build-theme --stdout            # print to stdout instead of writing .env

# After build-theme, regenerate downstream configs:
gen-vim-theme                   # config/nvim/colors/radix.vim + active-theme.lua
gen-ghostty-theme               # config/ghostty/active-theme
gen-terminal-icon               # ~/.config/ghostty/Ghostty.icns
```

Reload the shell or run `set -a; source "$DOTFILES/.env"; set +a` to pick up new vars.

## Shell config

All shell files live in `config/zsh/` and are symlinked to `~` by `setup.sh`.

| File | Loaded by | Purpose |
| ---- | --------- | ------- |
| `config/zsh/zshenv` | All shells | `$DOTFILES`, `$PATH`, loads `.env`, fzf theme, terminal icon config, API keys from Keychain, zsh-ai provider config |
| `config/zsh/zprofile` | Login shells | Homebrew init, Obsidian PATH |
| `config/zsh/zshrc` | Interactive shells | Oh My Zsh (plugins: git, tmux, zsh-ai, nvm, bun), aliases, functions, `motd` |
| `config/zsh/aliases.zsh` | Via zshrc | LM Studio shortcuts, `cc=claude`, `vim=nvim`, git log, navigation |
| `config/zsh/functions.zsh` | Via zshrc | Xcode helpers, LM Studio loader, `get-page-markdown()`, `remap_colors()`, ANSI audit |

## bin/ scripts

All scripts in `bin/` are on `$PATH` via `zshenv`.

| Script | Language | Description |
| ------ | -------- | ----------- |
| `build-theme` | Python | Generates `.env` from Radix scales. Supports `--accent`, `--grey`, `--stdout` |
| `gen-vim-theme` | Python | Writes `radix.vim` (VimScript) + `active-theme.lua` (Lua) from `THEME_*` vars |
| `gen-ghostty-theme` | Python | Writes Ghostty ANSI palette to `config/ghostty/active-theme` |
| `gen-terminal-icon` | Python (Pillow) | Generates `Ghostty.icns` with gradient, gloss, and text sheen |
| `gh-heatmap` | Python | GitHub contribution heatmap in the terminal via `gh api graphql` |
| `motd` | Bash | Message-of-the-day: composites a `chafa` avatar alongside a themed `gh-heatmap` |
| `fzf-preview` | Bash | Image/code previews in fzf using `chafa` (symbols) + `bat` |
| `build-clip-url` | Bash | Compiles `src/ClipURL.swift` into a macOS app for the `clip://` URL scheme |
| `show_tmux_iterm_img` | Bash | Workaround for rendering chafa images inside tmux via iTerm2 passthrough |

## tmux

Two-line status bar (`status 2`): line 1 is the header, line 2 is a thin colored separator.

- **Left**: terminal icon + username
- **Right**: git branch badge (error/success colored) + time
- **Window tabs**: current pane path or running command, accent-colored for active window

The tmux server inherits `THEME_*` from the launching shell. Theme-dependent options are baked in via inline `run` blocks at config load. Vim-style pane nav (`C-h/j/k/l`), `prefix + r` to reload, `prefix + k` for fzf file popup.

## Neovim

Config at `config/nvim/init.lua`. Uses `lazy.nvim` for plugin management. Active colorscheme is `active-theme` (generated Lua file).

Plugins: nvim-tree, which-key, tokyonight (fallback), toggleterm, image.nvim (kitty protocol), telescope (+fzf-native), themery (live theme picker), render-markdown.

## Zsh prompt

`config/oh-my-zsh/custom/themes/active.zsh-theme` -- powerline-style prompt using `THEME_*` stepped vars. Shows current directory (accent background), git branch (error/success colored), and exit code on failure.

## Secrets

API keys are stored in macOS Keychain and retrieved in `zshenv` via `security find-generic-password`. Never committed.

```bash
# Store a key:
security add-generic-password -a "$USER" -s "LM_STUDIO_API_KEY" -w "your-key" -T /usr/bin/security

# Currently stored: LM_STUDIO_API_KEY, HUGGING_FACE_TOKEN
```

## LM Studio

Three profiles per model configured in `config/lm_models_config.json`:

| Profile | Context |
| ------- | ------- |
| fast | 8K |
| balanced | 32K |
| quality | 65K |

Models: general (`google/gemma-4-26b-a4b`) and coder (`qwen/qwen3-coder-30b`). Exposed via OpenAI-compatible API at `http://localhost:1234/v1`. Also powers `zsh-ai` for in-terminal AI command suggestions.

## Structure

```text

```
