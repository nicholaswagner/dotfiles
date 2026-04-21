-- init.lua
-- Managed by dotfiles — symlinked from config/nvim/init.lua

-- ── Options ───────────────────────────────────────────────────────────────────

-- Display
vim.opt.termguicolors = true   -- true-color hex support (required for radix theme)
vim.opt.number        = true   -- line numbers
vim.opt.cursorline    = true   -- highlight current line
vim.opt.signcolumn    = "yes"  -- always show sign column (prevents layout shift)
vim.opt.colorcolumn   = "80"   -- ruler at 80 chars

-- Indentation
vim.opt.expandtab   = true  -- spaces instead of tabs
vim.opt.tabstop     = 2     -- visual width of a tab character
vim.opt.shiftwidth  = 2     -- indent size for >> and auto-indent
vim.opt.smartindent = true

-- Search
vim.opt.ignorecase = true   -- case-insensitive search...
vim.opt.smartcase  = true   -- ...unless the query has uppercase letters
vim.opt.hlsearch   = true   -- highlight matches
vim.opt.incsearch  = true   -- jump to match while typing

-- Behaviour
vim.opt.wrap       = false  -- no line wrapping
vim.opt.splitright = true   -- vertical splits open to the right
vim.opt.splitbelow = true   -- horizontal splits open below
vim.opt.mouse      = "a"    -- mouse support in all modes

-- Disable netrw (vim's built-in file browser) in favour of nvim-tree
vim.g.loaded_netrw       = 1
vim.g.loaded_netrwPlugin = 1

-- ── Leader key ───────────────────────────────────────────────────────────────
-- Must be set before plugins load so keymaps pick it up correctly
vim.g.mapleader      = " "  -- <Space> as leader
vim.g.maplocalleader = " "

-- ── Keymaps ──────────────────────────────────────────────────────────────────
local map = function(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
end

map("n", "<leader>e",  "<cmd>NvimTreeToggle<cr>",              "Toggle file tree")
map("n", "<leader>f",  "<cmd>NvimTreeFocus<cr>",               "Focus file tree")
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>",        "Find files")
map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>",         "Search in files")
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>",           "Open buffers")
map("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>",          "Recent files")
map("n", "<leader>fh", "<cmd>Telescope help_tags<cr>",         "Search help")

-- Clear search highlight with Escape
map("n", "<Esc>",       "<cmd>nohlsearch<cr>",  "Clear search highlight")
map("n", "<leader>th", "<cmd>Themery<cr>",     "Theme picker")

-- ── Plugin manager (lazy.nvim) ───────────────────────────────────────────────
-- Bootstraps lazy.nvim on first launch — clones it if not present
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ── Plugins ──────────────────────────────────────────────────────────────────
require("lazy").setup({

  -- File tree
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" }, -- file type icons
    config = function()
      require("nvim-tree").setup({
        view = {
          width = 35,
          side  = "left",
        },
        renderer = {
          group_empty = true,       -- collapse single-child dirs into one line
          highlight_git = true,     -- colour filenames by git status
          icons = {
            show = {
              git     = true,
              file    = true,
              folder  = true,
            },
          },
        },
        filters = {
          dotfiles = false,         -- show dotfiles by default (toggle with H)
        },
        git = {
          enable  = true,
          ignore  = false,          -- show git-ignored files (dimmed)
        },
        actions = {
          open_file = {
            quit_on_open = false,   -- keep tree open after opening a file
          },
        },
      })
    end,
  },

  -- Keybinding hints
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      delay = 500, -- ms after pressing a key before the popup appears
    },
  },

  -- Colorscheme
  {
    "folke/tokyonight.nvim",
    lazy = false,    -- load at startup
    priority = 1000, -- load before other plugins so colors are set first
    opts = {
      style = "moon", -- night | storm | moon | day
    },
  },

  -- Floating terminal
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
      open_mapping    = [[<C-\>]],  -- Ctrl+\ to toggle
      direction       = "float",
      float_opts      = {
        border   = "rounded",
        winblend = 10,             -- slight transparency
      },
      shade_terminals = true,
    },
  },

  -- Image rendering (Kitty graphics protocol — supported by Ghostty)
  -- Requires: brew install imagemagick luarocks && luarocks install magick --local
  {
    "3rd/image.nvim",
    build = "luarocks install magick --local",
    opts = {
      backend          = "kitty",
      max_width_window_percentage  = 40,
      max_height_window_percentage = 50,
    },
  },

  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make", -- compiles the fzf sorter for better performance
      },
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          layout_strategy = "horizontal",
          layout_config = { preview_width = 0.55 },
        },
        extensions = {
          -- image previews via image.nvim
          media_files = {
            filetypes = { "png", "jpg", "jpeg", "gif", "webp", "svg", "pdf" },
            find_cmd  = "fd",
          },
        },
      })
      telescope.load_extension("fzf")
    end,
  },

  -- Theme picker with live preview
  {
    "zaldih/themery.nvim",
    config = function()
      require("themery").setup({
        themes = {
          { name = "Tokyo Night",       colorscheme = "tokyonight"       },
          { name = "Tokyo Night Storm", colorscheme = "tokyonight-storm" },
          { name = "Tokyo Night Moon",  colorscheme = "tokyonight-moon"  },
          { name = "Tokyo Night Day",   colorscheme = "tokyonight-day"   },
          { name = "Radix",             colorscheme = "radix"            },
        },
        livePreview = true,
      })
    end,
  },

  -- Markdown rendering
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter", -- required for parsing
      "nvim-tree/nvim-web-devicons",     -- icons (already pulled in by nvim-tree)
    },
    ft = { "markdown" },                 -- only load for markdown files
    config = function()
      require("render-markdown").setup()
    end,
  },

})

-- ── Theme ─────────────────────────────────────────────────────────────────────
-- Must come after lazy.setup so the runtime path is fully populated
vim.cmd.colorscheme("active-theme")
