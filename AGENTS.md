# AGENTS.md

Single source of truth for AI coding agents (Claude Code, Codex, Cursor, etc.) working in this repository.

## What This Repo Is

A macOS dotfiles repo (Apple Silicon). The central feature is a **dynamic theme system** that produces consistent color palettes across the terminal (Ghostty), editor (Neovim), shell prompt (zsh), and multiplexer chrome (tmux) from a single source of truth — a `THEME_*` variable set in the shell environment.

## Setup and Install

```bash
./setup.sh                    # bootstrap: symlinks, brew bundle, theme generation
brew bundle --file=Brewfile   # install/update Homebrew packages (alias: brewfile)
```

`setup.sh` is idempotent — symlinks use `ln -sf`, submodule init is guarded. Safe to re-run.

## Theme System

The pipeline: **`THEME_*` env vars** → generator scripts → output files.

`THEME_*` variables can come from two places:
- **External theme repo** (current default): `config/zsh/zshenv` sources a `.env-*` file from `~/Repos/dev.nicholaswagner/terminal-colors/themes/`. That's the live source today.
- **Local `.env`**: This repo's root `.env` is the legacy source — still committed and parseable, but `zshenv` no longer reads it. `scripts/build-theme.py` writes to it.

Either way, the variables get exported with `set -a; source <file>; set +a`. Python generators read `THEME_*` from `os.environ`.

```bash
python3 scripts/build-theme.py --accent violet   # writes .env (--accent locks accent, rest randomizes)
python3 scripts/build-theme.py --stdout          # print to stdout instead of writing
python3 scripts/gen-vim-theme.py                 # writes config/nvim/colors/radix.vim + active-theme.lua
python3 scripts/build-ghostty-theme.py           # writes config/ghostty/active-theme
uv run scripts/gen-terminal-icon.py              # writes ~/.config/ghostty/Ghostty.icns (uses uv shebang)
```

Note: `scripts/` is **not** on `$PATH`. Invoke scripts by explicit path or via aliases. After generating, reload the shell to pick up new vars.

**The `THEME_*` variable convention:**

- Six 12-step Radix color scales: `THEME_ACCENT_*`, `THEME_GREY_*`, `THEME_ERROR_*`, `THEME_WARNING_*`, `THEME_SUCCESS_*`, `THEME_INFO_*`
- Step 9 = solid accent (peak chroma); steps 1–2 = backgrounds; steps 11–12 = text
- `THEME_USE_DARK` — space-separated list of roles where step 9 needs dark foreground text (e.g., `warning` when yellow is the warning solid)
- `THEME_ACCENT_SCALE_NAME`, `THEME_GREY_SCALE_NAME`, etc. — which Radix scale was chosen
- Meta: `THEME_TYPE` (always `"dark"`)

All Radix scale data lives in `scripts/darkcolors.py` (25 accent scales, 6 grey scales, semantic pools, natural grey pairings). A `scripts/lightcolors.py` exists for future light-theme support.

Generated output files (`active-theme`, `radix.vim`, `active-theme.lua`) are **not committed** — they're regenerated from `THEME_*` vars.

## Symlink Map

`setup.sh` creates these symlinks:

| Dotfiles path | System path |
|---|---|
| `config/zsh/zshenv` | `~/.zshenv` |
| `config/zsh/zprofile` | `~/.zprofile` |
| `config/zsh/zshrc` | `~/.zshrc` |
| `config/oh-my-zsh/custom/` | `$ZSH/custom/` |
| `config/tmux/tmux.conf` | `~/.tmux.conf` |
| `config/ghostty/ghostty.conf` | `~/Library/Application Support/com.mitchellh.ghostty/config` |
| `config/ghostty/active-theme` | `~/.config/ghostty/themes/active-theme` |
| `config/nvim/init.lua` | `~/.config/nvim/init.lua` |
| `config/nvim/colors/radix.vim` | `~/.config/nvim/colors/radix.vim` |
| `config/nvim/colors/active-theme.lua` | `~/.config/nvim/colors/active-theme.lua` |
| `config/gitconfig` | `~/.gitconfig` |
| `submodules/ghostty-themes/ghostty-themes` | `~/.local/bin/ghostty-themes` |

Ghostty on macOS reads `~/Library/Application Support/com.mitchellh.ghostty/config` in preference to `~/.config/ghostty/config`, so the config symlink lives there. The `theme = active-theme` directive in that config resolves to `~/.config/ghostty/themes/active-theme`.

## Shell Config Loading Order

- **`config/zsh/zshenv`** — all shells; sets `$DOTFILES`, sources the active theme file from the external `terminal-colors` repo, loads `config/fzf-theme.sh`, sets terminal icon config and LM Studio env vars, retrieves API keys from macOS Keychain, configures `zsh-ai`, sets `bun` and `nvm` paths
- **`config/zsh/zprofile`** — login shells; Homebrew init, Obsidian path
- **`config/zsh/zshrc`** — interactive shells; Oh My Zsh (plugins: `git tmux zsh-ai nvm bun direnv`), sources `aliases.zsh` and `functions.zsh`, registers `_cmd_rule` preexec hook (colored `─` separator before each command), runs `motd` on startup
- **`config/zsh/aliases.zsh`** — LM Studio shortcuts (`lms-fast/balanced/quality`, plus `-coder-*` variants), `cc=claude`, `vim=nvim`, `git-log`, `brewfile`, navigation, `readme=glow`, `source-maps`, `ghhtml`
- **`config/zsh/functions.zsh`** — Xcode helpers (`xcode_gen/build/run`), `lms_load`, ffmpeg color remap (`remap_colors`, `build_remap_filter`), `window-title`, OSC 7 directory tracking, `ansi_audit`, terminal color utilities (`txt`, `style_codes`, `hex_to_decimal`, `supports_color`), `get-page-markdown`, `do-it-live` (nodemon wrapper), `md_to_terminal_links`, `cc-storytime` (Claude Code session → Siri TTS), `ghostty-html`

## scripts/

Python and shell helpers. **Not on `$PATH`** — invoke by explicit path or wire up an alias.

| Script | Language | Description |
|---|---|---|
| `build-theme.py` | Python | Generates `$DOTFILES/.env` from Radix scales. `--accent <name|hex>` locks accent, `--stdout` prints instead of writing |
| `build-ghostty-theme.py` | Python | Reads `THEME_*` and writes `config/ghostty/active-theme` (palette + selection + cursor) |
| `gen-vim-theme.py` | Python | Writes `config/nvim/colors/radix.vim` (VimScript) and `active-theme.lua` (Lua) |
| `gen-terminal-icon.py` | Python (`uv run`) | Generates `~/.config/ghostty/Ghostty.icns` with gradient, gloss, and text sheen. Configurable via env vars (`TERMINAL_ICON`, `TERMINAL_ICON_CORNER_RADIUS`, etc.) |
| `darkcolors.py` | Python | Radix dark-theme scale data + semantic/grey pairings (imported by `build-theme.py`) |
| `lightcolors.py` | Python | Radix light-theme scale data (not currently wired) |
| `bashenv.sh` | Bash | Loads a `.env` file with comment-aware parsing, optionally execs a command in that env |
| `build-clip-url.sh` | Bash | Compiles `src/ClipURL.swift` → `~/Applications/ClipURL.app` (handles `clip://` URL scheme) |
| `dev.py` | Python | Dev helper (project-specific) |
| `fzf-preview.sh` | Bash | fzf preview wrapper: `chafa` (symbols) for images, `bat` for code |
| `motd.sh` | Zsh | Message-of-the-day: composites a `chafa`-rendered avatar at terminal startup. Skips rendering in VSCode terminals. Falls back to `show_tmux_iterm_img.sh` for iTerm2-in-tmux |
| `show_tmux_iterm_img.sh` | Bash | Workaround for rendering chafa images inside tmux via iTerm2 passthrough. Uses DCS double-escaping plus a Device Status Report (`\033[6n`) handshake to block until the terminal confirms |
| `term-img.sh` | Bash | Terminal image helper |
| `utils.sh` | Bash | Shared shell utilities |

## tmux

The status bar uses two lines (`status 2`): line 1 is the header, line 2 is a thin colored separator.

The tmux server inherits `THEME_*` from the zsh that launches it (zshenv sources the active theme file). `tmux.conf` uses inline `run 'tmux set -g ...'` blocks to bake those values into `pane-border-style` and the window-status formats at config load. Status bar scripts read `THEME_*` from the inherited tmux server env on each tick — no file sourcing per second. tmux accepts hex colors directly in style strings.

- `config/tmux/tmux.conf` — main config: true color, hyperlinks, `status 2`, `status-position top`, `status-interval 1`, `allow-passthrough all` (for Claude Code), mouse on, vim-style pane nav (`C-h/j/k/l`), `prefix + r` to reload, `prefix + k` for fzf file popup. Theme-dependent options are set via inline `run` blocks that shell-expand `$THEME_*`
- `config/tmux/tmux-header.sh` — status line content: left = user icon + name, right = git branch badge (error/success colored) + time. Uses a `segment()` helper that outputs `#[bg=...,fg=...] content #[default]`

## Neovim

Config at `config/nvim/init.lua`. Uses `lazy.nvim` for plugin management. Active colorscheme is `active-theme` (generated Lua file). Plugins: nvim-tree, which-key, tokyonight (fallback), toggleterm, image.nvim (kitty protocol), telescope (+fzf-native), themery (live theme picker), render-markdown.

## Zsh Prompt

Active theme: `config/oh-my-zsh/custom/themes/active.zsh-theme` — powerline-style prompt using `THEME_*` stepped vars. Shows current directory (accent bg), git branch (error/success colored), and exit code on failure. All ANSI escapes wrapped in `%{...%}` for correct zero-width counting.

## Secrets

API keys are stored in macOS Keychain and retrieved in `config/zsh/zshenv` via:

```bash
security find-generic-password -a "$USER" -s "KEY_NAME" -w
```

Currently retrieved: `LM_STUDIO_API_KEY`, `HUGGING_FACE_TOKEN`. `setup.sh` checks for `LM_STUDIO_API_KEY` and prompts if missing.

## LM Studio

Three profiles per model configured in `config/lm_models_config.json`:

- **fast** — 8K context
- **balanced** — 32K context
- **quality** — 65K context

Models: general (`google/gemma-4-26b-a4b`) and coder (`qwen/qwen3-coder-30b`). Exposed via OpenAI-compatible API at `http://localhost:1234/v1`. The `lms_load()` function in `config/zsh/functions.zsh` loads models by profile name with auto-TTL. Aliases `lms-fast/balanced/quality` and `lms-coder-*` cover the common cases.

## Submodules

- `submodules/source-maps-downloader` — sourcemap-grabbing utility; exposed via `source-maps` alias
- `submodules/ghostty-themes` — Ghostty theme previewer; symlinked to `~/.local/bin/ghostty-themes` by `setup.sh`

## Outstanding Issues

`TODO.md` at the repo root tracks known caveats and unfinished refactor work — check it before making cross-cutting changes.

## ClipURL App

`src/ClipURL.swift` + `scripts/build-clip-url.sh` create `~/Applications/ClipURL.app`, a background macOS app (no dock icon, `LSUIElement=true`) that handles the `clip://` URL scheme. Used by the Claude Code statusline (`~/.claude/statusline.sh`) so that clicking the session ID hyperlink silently copies the transcript path to the clipboard.
