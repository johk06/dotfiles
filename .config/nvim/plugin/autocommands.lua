local autocmd = vim.api.nvim_create_autocmd
local api = vim.api
local utils = require("config.utils")

-- Window Title {{{
-- change the title in a more intelligent way
autocmd({ "BufEnter", "BufReadPost", "BufNewFile", "VimEnter" }, {
    desc = "Change Window Title",
    callback = function()
        local name, _, _ = utils.format_buf_name(api.nvim_get_current_buf(), false)

        vim.o.titlestring = "nv: " .. (name or "[-]")
    end
})
vim.o.titlestring = "nv: Neovim" -- set initial
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

-- Redact password files
autocmd("VimEnter", {
    pattern = "/dev/shm/pass.?*/?*.txt",
    callback = function(ev)
        vim.bo[ev.buf].filetype = "pass"
    end
})

-- Try to set a compiler based on the file's shebang
autocmd("BufEnter", {
    desc = "Set compiler based on shebang",
    callback = function(ev)
        local fst = api.nvim_buf_get_lines(ev.buf, 0, 1, false)[1]
        if not vim.startswith(fst, "#!") or vim.bo[ev.buf].makeprg ~= "" then
            return
        end

        local interpreter = fst:sub(3):gsub("^/usr/bin/env%s*", "")
        local ok, _ = pcall(api.nvim_cmd, {
            cmd = "compiler",
            args = { interpreter },
        }, {})
        if not ok then -- Compiler is not known to vim, do our best
            vim.bo[ev.buf].makeprg = ("%s %%:S"):format(vim.fn.shellescape(interpreter))
        end
    end
})
