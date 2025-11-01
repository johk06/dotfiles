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
vim.o.titlestring = "nv: NeoVIM" -- set initial
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
-- TODO: add actual heuristics for what to do
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

-- set the primary selection to the last register on window focus loss
-- saves me from having to go back when I forgot to specify "+
-- when working in more than one terminal window
autocmd("FocusLost", {
    callback = function()
        vim.fn.setreg("*", vim.fn.getreg("\""))
    end
})

-- View files on the internet {{{
---@type (fun(url: string): string?)[]
local url_transforms = {
    -- use raw versions for files from github
    function(url)
        if vim.startswith(url, "https://github.com") then
            local suburl = url:gsub("^https://github.com/", "")
            local repo = suburl:match("([^/]+/[^/]+)")
            local path = repo and suburl:sub(#repo) or ""

            if suburl == repo then           -- README for plain repo
                return ("https://raw.githubusercontent.com/%s/master/README.md"):format(suburl)
            elseif path:match("/blob/") then -- files
                local raw = url:gsub("github%.com", "raw.githubusercontent.com"):gsub("/blob/", "/")
                return raw
            end
        end
    end,
}

local ns = api.nvim_create_namespace("config.webview")

Jhk.WebIncludeExpr = function()
    local path = vim.v.fname
    local base_url = api.nvim_buf_get_name(0)
    return base_url .. path
end

autocmd("BufReadCmd", {
    pattern = { "https://*", "http://*" },
    callback = function(ev)
        local buf = ev.buf
        local bo = vim.bo[buf]
        bo.swapfile = false
        bo.undofile = false

        local url = api.nvim_buf_get_name(buf):gsub("/$", "")
        api.nvim_buf_set_name(buf, url) -- normalize URLs ending in /
        for _, transform in ipairs(url_transforms) do
            local res = transform(url)
            if res then
                url = res
                break
            end
        end
        api.nvim_buf_set_extmark(buf, ns, 0, 0, {
            virt_text = {
                { "Curl-ing buffer from " }, { url, "Underlined" }, { "...", "NonText" }
            }
        })

        vim.system({ "curl", "--silent", "--fail-with-body", "--", url }, {

        }, vim.schedule_wrap(function(out)
            api.nvim_buf_clear_namespace(buf, ns, 0, -1)
            local ft
            local lines = vim.split(out.stdout, "\n")
            if out.code ~= 0 then
                ft = "markdown"
                local message = {
                    "# Error",
                    ("Failed to get [%s](%s)"):format(url, url),
                    "",
                    ("# Curl exited with %d"):format(out.code),
                }
                vim.list_extend(message, lines)
                api.nvim_buf_set_lines(buf, 0, -1, false, message)

                vim.wo[0].conceallevel = 2
                vim.wo[0].concealcursor = "nvic"
            else
                api.nvim_buf_set_lines(buf, 0, -1, false, lines)

                -- only try name-based filetypes when header etc based ones fail
                -- if we don't do this, common TLDs like .org or .com will break a lot of sites
                ft = vim.filetype.match { contents = lines }
                if not ft then
                    ft = vim.filetype.match { filename = url }
                end
            end

            utils.buf_drop_undo(buf)

            bo.filetype = ft or "html"
            bo.modified = false
            bo.buftype = "nowrite"

            -- resolve paths relative to the site
            bo.includeexpr = "v:lua.Jhk.WebIncludeExpr()"
        end))
    end
})
-- }}}
