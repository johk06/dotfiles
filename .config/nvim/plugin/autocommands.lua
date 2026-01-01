local autocmd = vim.api.nvim_create_autocmd
local api = vim.api
local utils = require("config.utils")

-- Window Title {{{
-- change the title in a more intelligent way
autocmd({ "BufEnter", "BufReadPost", "BufNewFile", "VimEnter" }, {
    callback = function()
        local name, _, _ = utils.format_buf_name(api.nvim_get_current_buf(), false)

        vim.o.titlestring = "nv: " .. (name or "[-]")
    end
})
vim.o.titlestring = "nv: Neovim" -- set initial
-- }}}

--[[ Mode based 'number' and 'relativenumber' {{{
change line number based on mode:
- command mode: make it absolute for ranges
- normal mode: keep relative motions fast
]]

-- debounce cmdline enter events to make sure we don't have flickering for non user cmdline use
-- e.g. mappings using : instead of <cmd>
local cmdline_debounce_timer

utils.autogroup("config.cmdline_linenr", {
    CmdlineEnter = function()
        cmdline_debounce_timer = assert(vim.uv.new_timer())
        cmdline_debounce_timer:start(100, 0, vim.schedule_wrap(function()
            if vim.o.number then
                vim.o.relativenumber = false
                api.nvim__redraw({ statuscolumn = true })
            end
        end))
    end,

    CmdlineLeave = function()
        if cmdline_debounce_timer then
            cmdline_debounce_timer:stop()
            cmdline_debounce_timer = nil
        end
        if vim.o.number then
            vim.o.relativenumber = true
        end
    end,
})
-- }}}

-- Smarter :h 'autochdir' {{{
-- when opening a file, automatically lcd to its git repo ancestor
-- if already in a repo, behave somewhat like autocd

utils.autogroup("config.chdir", {
    BufWinEnter = function(ev)
        if vim.bo[ev.buf].filetype == "help" then
            return
        end

        local path = api.nvim_buf_get_name(ev.buf)
        local git_root = vim.fs.root(path, ".git")
        local pwd = vim.fn.getcwd()
        if git_root and not vim.startswith(pwd, git_root) then
            vim.cmd.lcd(git_root)
        end
    end,

    -- show when the dir changes
    DirChanged = vim.schedule_wrap(function()
        local name = utils.expand_home(vim.fn.getcwd(0, 0))
        api.nvim_echo({ { "pwd: ", "NonText" }, { name, "Directory" } }, false, {})
    end)
})
-- }}}

-- auto resize on window resize
autocmd("VimResized", {
    callback = function()
        vim.cmd.wincmd("=")
    end
})

-- highlight yanked text
autocmd("TextYankPost", {
    callback = function()
        vim.hl.on_yank { timeout = 120, higroup = "Yanked" }
    end
})

--[[ Set the primary selection to the last register on window focus loss
 This saves me from having to go back when I forgot to specify "+
 when working in more than one terminal window ]]
autocmd("FocusLost", {
    callback = function()
        vim.fn.setreg("*", vim.fn.getreg("\""))
    end
})
