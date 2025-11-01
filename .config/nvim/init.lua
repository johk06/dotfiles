--[[ Information {{{
Entry point to *almost* all of my neovim configuration (barring ftplugins and after/)
This file is mainly concerned with setting options
and doing everything required for startup.
Once it is done bootstrapping neovim, little if anything remains of it

TODO: figure out note-taking solution
TODO: repl
}}} ]]

-- Global namespace for functions that need to be callable from vimscript
_G.Jhk = {}

vim.cmd.colorscheme("mynord")

-- Environment {{{
-- make sure that any child processes use the parent neovim
vim.env.EDITOR = "nvr"
vim.env.GIT_EDITOR = "nvr -cc Sp -c 'se bufhidden=delete' --remote-wait"
-- }}}

-- only open the welcome screen if stdin is empty
-- and there are no command line arguments
local should_open_start_screen = vim.fn.argc() == 0
vim.api.nvim_create_autocmd("StdinReadPre", {
    once = true,
    callback = function()
        should_open_start_screen = false
    end
})

local opt = vim.opt
local o = vim.o
local g = vim.g

g.mapleader = "\\"
g.maplocalleader = "\\"

-- Basic options {{{
o.cursorline = true
o.cursorlineopt = "number"
o.expandtab = true
o.hlsearch = true
o.ignorecase = true
o.incsearch = true
o.number = true
o.numberwidth = 2
o.relativenumber = true
o.scrolloff = 8
o.shiftwidth = 4
o.showmode = false
o.smartcase = true
o.title = true
o.undofile = true
o.winborder = "rounded"
-- }}}

-- Wrapping {{{
-- wrap at whitespace, indent wrapped lines and show an indicator
o.wrap = true
o.linebreak = true
o.breakindent = true
o.breakindentopt = "sbr"
o.showbreak = ""
-- }}}

-- i don't know why this isn't the default, much more intuitive in my opinion
o.splitright = true
o.splitbelow = true

local shm = opt.shortmess
shm:append("S") -- hide search count
shm:append("s") -- hide search hit x
shm:append("q") -- hide macro

-- Characters {{{
opt.fillchars = {
    -- it's visible from the gaps anyways
    diff = " ",
    lastline = "",
}

opt.listchars = {
    eol = "",
    tab = "󰌒 ",
    trail = "·",
    nbsp = "󱁐"
}
-- }}}

opt.diffopt = {
    "filler",
    "internal",
    "closeoff",
    "context:4", -- 6 is a bit too much for me
}

-- Search {{{
-- current directory, children and parent
opt.path = {
    ".",
    "*",
    "../*",
}

opt.cdpath = {
    ".",
    "*",
    "../*",
}

opt.wildignore = {
    -- output formats
    "*.o",
    "*.pdf",

    -- no need to edit directly
    ".git",
}
-- }}}

opt.guicursor = {
    "n-o-v:block",            -- normal, o-pending, visual: block
    "r-t:hor20",              -- replace, terminal: underscore
    "i-c-ci-cr:ver10",        -- insert, command: bar
    "n-c-ci-cr-r-v:blinkon1", -- all except o-pending: blink
}

-- ftplugins {{{
g.c_syntax_for_h = true -- i use C more than C++

-- make manpage formatting decent
g.man_hardwrap = 0
g.ft_man_folding_enable = 1

g.loaded_spellfile_plugin = 1 -- use my own code instead
-- }}}

-- Lazy {{{
-- use lazy for the remaining config
-- all the package definitions in ./lua/plugins/ will be loaded
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- bootstrap
if not vim.uv.fs_stat(lazypath) then
    vim.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
opt.rtp:prepend(lazypath)

require("lazy").setup("plugins", {
    -- so i can work on my own local plugins
    dev = {
        path = "~/ws/",
        patterns = { "johk06" },
        fallback = true,
    },

    install = {
        colorscheme = { "mynord" },
    },

    -- just plain annoying
    change_detection = {
        enabled = false,
        notify  = false,
    },

    ui = {
        title = "Plugins - Lazy",
        backdrop = 100,
        pills = false,
        border = "rounded",
        icons = {
            loaded     = "󰗠",
            not_loaded = "󰍷",
            ft         = "󰈔",
            cmd        = "",
            event      = "󰍢",
            lazy       = "󰒲",
            start      = "󰐥",
            runtime    = "",
            list       = {
                "󱦰",
                "󱞩",
                "󱞩",
                "󱞩",
            },
        }
    },
    performance = {
        rtp = {
            reset = true,
            disabled_plugins = {
                "tutor",   -- I *think* I know vim well enough

                "matchit", -- use matchup instead
                "matchparen",

                "spellfile", -- use my own

                -- I use neither of those
                "netrwPlugin",
                "rplugin",
            }
        }
    }
})
-- }}}

-- Diagnostics {{{
local hlgroups = {
    "DiagnosticSignError",
    "DiagnosticSignWarn",
    "DiagnosticSignInfo",
    "DiagnosticSignHint",
}
vim.diagnostic.config {
    virtual_text = {
        prefix = "!",
    },
    signs = {
        numhl = hlgroups,
        text = { "", "", "", "" }
    },
    float = {
        border = "rounded",
    }
}
-- }}}

-- Load Config {{{
require("config.treesitter")   -- custom treesitter features
require("config.autocommands") -- set autocommands that don't fit anywhere else
require("config.mappings")     -- set all the mappings
require("config.commands")     -- global custom commands
require("config.statusline")   -- at bottom of screen
require("config.bufferline")   -- at the top
require("config.lsp")          -- language servers
require("config.spell")        -- automatically install spelling languages

-- load UI components
local ui = require("config.lib.ui")
vim.ui.input = ui.nvim_input
-- }}}

-- for some reason lazy deactivates it
o.modeline = true

-- create this autocommand after neovim had a chance to read from stdin
vim.api.nvim_create_autocmd("User", {
    pattern = "LazyVimStarted",
    once = true,
    callback = function()
        if should_open_start_screen then
            require("config.dashboard").show()
        end
    end
})
