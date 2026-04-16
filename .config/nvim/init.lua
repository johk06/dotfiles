--[[ Information & Architecture {{{

This file (init.lua) sets options and does everything needed at startup.
It does *not* create mappings, commands &c.

Mappings & Commands are created in:
- plugin/mappings.lua - Global, with little or no plugin dependencies
- lua/plugins/*.lua   - Plugin-specific
- lua/config/lsp.lua  - Those that require an LSP to be there

Contents of lua/:
- config/
    - lib/      - Modules that are useful and factor out repetitive tasks
    - plugins/  - Additional configuration or helpers for plugin configuration
    - *.lua     - Additional configuration or *very* common helpers
- plugins/      - The pack plugin specifications
- theme/        - My colorscheme

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

-- Only open the welcome screen if stdin is empty
-- and if there are no command line arguments
local should_open_start_screen = vim.fn.argc() == 0
if should_open_start_screen then
    vim.api.nvim_create_autocmd("StdinReadPre", {
        once = true,
        callback = function()
            should_open_start_screen = false
        end
    })
end

local opt = vim.opt
local o = vim.o
local g = vim.g

-- Do not bloat the runtimepath with too much Vim stuff
opt.runtimepath = vim.tbl_filter(function(p)
    return not vim.startswith(p, "/usr/share/vim")
end, opt.runtimepath:get())

g.mapleader = "\\"
g.maplocalleader = "\\"

-- Basic options {{{
o.cursorline = true
o.cursorlineopt = "number"

o.expandtab = true
o.shiftwidth = 4

o.hlsearch = true
o.ignorecase = true
o.smartcase = true
o.incsearch = true

o.mouse = "ar"
o.mousemodel = "extend"

o.number = true
o.numberwidth = 2
o.relativenumber = true

o.scrolloff = 8
o.showmode = false
o.title = true
o.undofile = true
o.winborder = "rounded"

-- I don't know why this isn't the default, much more intuitive in my opinion
o.splitright = true
o.splitbelow = true

local shm = opt.shortmess
shm:append("S") -- hide search count
shm:append("s") -- hide search hit x
shm:append("q") -- hide macro
shm:append("I") -- no :intro

-- TODO: maybe? This allows me to have project specific settings
o.exrc = true

-- For some reason this takes a while to get set
o.termguicolors = true
-- }}}
-- Extra Filetypes {{{
vim.filetype.add {
    extension = {
        psv = "psv",
        ripe = "ripe",
        qalc = "qalc"
    },
}
-- }}}
-- Wrapping {{{
-- wrap at whitespace, indent wrapped lines and show an indicator
o.wrap = true
o.linebreak = true
o.breakindent = true
o.breakindentopt = "sbr"
o.showbreak = ""
-- }}}
-- Display {{{
opt.fillchars = {
    -- it's visible from the gaps anyways
    diff = " ",
    lastline = "",
    msgsep = "─",
}

opt.listchars = {
    eol = "",
    multispace = " · ",
    nbsp = "󱁐",
    space = "·",
    tab = "󰌒 ",
    trail = "·",
}

opt.guicursor = {
    "n-o-v:block",            -- normal, o-pending, visual: block
    "r-t:hor20",              -- replace, terminal: underscore
    "i-c-ci-cr:ver10",        -- insert, command: bar
    "n-c-ci-cr-r-v:blinkon1", -- all except o-pending: blink
}

opt.diffopt = {
    "filler",
    "internal",
    "closeoff",
    -- 6 is too much for me
    "context:2",
    --  This is nice, it reduces the amount of changes shown for most things
    "inline:word",
}
-- }}}
-- File Search {{{
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

    -- no need to edit directly
    ".git",
}
-- }}}
-- Filetype Plugins {{{
g.c_syntax_for_h = true -- i use C more than C++

-- make manpage formatting decent
g.man_hardwrap = 0
g.ft_man_folding_enable = 1
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
-- Load Packages {{{
vim.pack.add({ 'https://github.com/zuqini/zpack.nvim' })
require("zpack").setup()
-- }}}
-- Load Config {{{
require("config.lsp")        -- language servers
require("config.editor")     -- extra features
require("config.langabbrev") -- smart insert mode abbreviations

-- load UI components
local ui = require("config.lib.ui")
vim.ui.input = ui.nvim_input

require("vim._core.ui2").enable {
    pager = {
        height = 0.3,
    },
}
-- }}}

-- Create this autocommand after neovim had a chance to read from stdin
if should_open_start_screen then
    vim.schedule(function()
        if should_open_start_screen then
            require("config.dashboard").show()
        end
    end)
end
