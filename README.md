# ~/dotfiles

![A screenshot of a terminal with a custom theme](assets/tokyosandwich.png)

My personal dotfiles collection for macOS (Apple Silicon).
I've had Claude make an effort to summarize what's going on in here, but YMMV.

At the moment I'm playing around with a terminal theme engine heavily ~~stolen~~ inspired by the radix-ui team.

---
> [!NOTE]
> I previously had this doing a sparse checkout on the nerd-fonts repo so I could quickly patch together a custom `DankMono` Nerd Font with some additional custom glyphs, but that project is huge and it's something I do maybe once every couple of years, so I've currently got it commented out. (BTW — if you're not using [DankMono](https://philpl.gumroad.com/l/dank-mono) you really should be.)

---

> [!IMPORTANT]
> Theming is still a hacked-together PoC. Currently it's `darkmode` only, and you can either have it build you a random radix-ui/colors inspired palette, or you can give it an accent color (it assumes accent_9) and it will generate the palette + grey scales for you. It generates a zsh theme + nvim theme + ghostty app icon that includes whatever nerdy mark you've currently got set in the `zshenv` file.

---

> [!TIP]
> There's a bug with trying to display kitty / iTerm graphics inside `tmux` when you use `iTerm.app`. I'm honestly still not entirely sure what the *true* root cause is, but if you're trying to get your setup working you might find `scripts/show_tmux_iterm_img.sh` useful.

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

`setup.sh` *should be* idempotent — symlinks use `ln -sf`, submodule init is guarded. Safe to re-run.

## What it sets up

| Tool | Description |
| ---- | ----------- |
| [Oh My Zsh](https://ohmyz.sh) | Zsh framework with plugins and themes |
| [Homebrew](https://brew.sh) | Package manager — installs everything in `Brewfile` |
| [Ghostty](https://ghostty.org) | GPU-accelerated terminal with true color and image support |
| [Neovim](https://neovim.io) | Editor with lazy.nvim plugin management and generated colorscheme |
| [tmux](https://github.com/tmux/tmux) | Terminal multiplexer with themed two-line status bar |
| [nvm](https://github.com/nvm-sh/nvm) | Node Version Manager + latest Node |
| [bun](https://bun.sh) | JavaScript runtime |
| [LM Studio](https://lmstudio.ai) | Local LLM inference via OpenAI-compatible API |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder with themed colors and image previews |
| [chafa](https://hpjansson.org/chafa/) | Terminal image rendering (used by `motd.sh` and `fzf-preview.sh`) |

## Theme system

Pipeline: **`THEME_*` env vars → generator scripts → output files.** Built on [Radix UI color scales](https://www.radix-ui.com/colors) — 25 accent scales, 6 grey scales, semantic pools for error/warning/success/info, and natural grey pairings. Each scale has 12 steps with defined roles (backgrounds, borders, solids, text).

Where the `THEME_*` vars come from is in flux. `config/zsh/zshenv` currently sources a theme file from an external `~/Repos/dev.nicholaswagner/terminal-colors/themes/` repo. The local root `.env` is still a valid source — `scripts/build-theme.py` writes to it — but it isn't what the live shell loads today.

```bash
python3 scripts/build-theme.py                       # fully random palette → .env
python3 scripts/build-theme.py --accent violet       # lock accent, randomize the rest
python3 scripts/build-theme.py --accent '#8e4ec6'    # custom hex with generated 12-step scale
python3 scripts/build-theme.py --stdout              # print to stdout instead of writing .env

# After build-theme, regenerate downstream configs:
python3 scripts/gen-vim-theme.py                     # config/nvim/colors/radix.vim + active-theme.lua
python3 scripts/build-ghostty-theme.py               # config/ghostty/active-theme
uv run scripts/gen-terminal-icon.py                  # ~/.config/ghostty/Ghostty.icns
```

Reload the shell to pick up new vars.

## Shell config

All shell files live in `config/zsh/` and are symlinked to `~` by `setup.sh`.

| File | Loaded by | Purpose |
| ---- | --------- | ------- |
| `config/zsh/zshenv` | All shells | `$DOTFILES`, sources active theme from `terminal-colors` repo, fzf theme, terminal-icon config, API keys from Keychain, zsh-ai provider, bun/nvm paths |
| `config/zsh/zprofile` | Login shells | Homebrew init, Obsidian PATH |
| `config/zsh/zshrc` | Interactive shells | Oh My Zsh (plugins: `git tmux zsh-ai nvm bun direnv`), `aliases.zsh`, `functions.zsh`, `_cmd_rule` preexec hook, `motd` |
| `config/zsh/aliases.zsh` | Via zshrc | LM Studio shortcuts (general + coder), `cc=claude`, `vim=nvim`, `git-log`, `brewfile`, navigation, `readme=glow`, `source-maps`, `ghhtml` |
| `config/zsh/functions.zsh` | Via zshrc | Xcode helpers, `lms_load`, ffmpeg color remap, `get-page-markdown`, ANSI audit, terminal color utilities, `do-it-live`, `cc-storytime`, `ghostty-html` |

## scripts/

Helpers live under `scripts/`. They are **not** on `$PATH` — invoke by explicit path.

| Script | Language | Description |
| ------ | -------- | ----------- |
| `build-theme.py` | Python | Generates `.env` from Radix scales. Supports `--accent`, `--stdout` |
| `build-ghostty-theme.py` | Python | Writes Ghostty palette to `config/ghostty/active-theme` |
| `gen-vim-theme.py` | Python | Writes `radix.vim` (VimScript) + `active-theme.lua` (Lua) from `THEME_*` vars |
| `gen-terminal-icon.py` | Python (uv) | Generates `Ghostty.icns` with gradient, gloss, and text sheen |
| `darkcolors.py` | Python | Radix dark scale data (imported by `build-theme.py`) |
| `lightcolors.py` | Python | Radix light scale data (not currently wired) |
| `motd.sh` | Zsh | Message-of-the-day: composites a `chafa` avatar at terminal startup |
| `fzf-preview.sh` | Bash | Image/code previews in fzf using `chafa` (symbols) + `bat` |
| `build-clip-url.sh` | Bash | Compiles `src/ClipURL.swift` into a macOS app for the `clip://` URL scheme |
| `show_tmux_iterm_img.sh` | Bash | Workaround for rendering chafa images inside tmux via iTerm2 passthrough |
| `bashenv.sh` | Bash | Comment-aware `.env` loader; optionally execs a command in that env |
| `term-img.sh` | Bash | Terminal image helper |
| `utils.sh` | Bash | Shared shell utilities |
| `dev.py` | Python | Dev helper |

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

`config/oh-my-zsh/custom/themes/active.zsh-theme` — powerline-style prompt using `THEME_*` stepped vars. Shows current directory (accent background), git branch (error/success colored), and exit code on failure.

## Ghostty config location

Ghostty on macOS reads from `~/Library/Application Support/com.mitchellh.ghostty/config` in preference to `~/.config/ghostty/config`, so `setup.sh` symlinks the Application Support path to `config/ghostty/ghostty.conf`. The `theme = active-theme` directive in that config resolves to `~/.config/ghostty/themes/active-theme`, which is symlinked to `config/ghostty/active-theme`.

## Submodules

- `submodules/source-maps-downloader` — sourcemap-grabbing utility; exposed via the `source-maps` alias
- `submodules/ghostty-themes` — Ghostty theme previewer; symlinked to `~/.local/bin/ghostty-themes` by `setup.sh`

## Secrets

API keys are stored in macOS Keychain and retrieved in `zshenv` via `security find-generic-password`. Never committed.

```bash
# Store a key:
security add-generic-password -a "$USER" -s "LM_STUDIO_API_KEY" -w "your-key" -T /usr/bin/security

# Currently retrieved: LM_STUDIO_API_KEY, HUGGING_FACE_TOKEN
```

## LM Studio

Three profiles per model configured in `config/lm_models_config.json`:

| Profile | Context |
| ------- | ------- |
| fast | 8K |
| balanced | 32K |
| quality | 65K |

Models: general (`google/gemma-4-26b-a4b`) and coder (`qwen/qwen3-coder-30b`). Exposed via OpenAI-compatible API at `http://localhost:1234/v1`. Also powers `zsh-ai` for in-terminal AI command suggestions.
