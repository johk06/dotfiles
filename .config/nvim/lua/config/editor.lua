--[[ Information {{{
Additional global functionality for Neovim
}}} ]]

local api = vim.api
local ns = vim.api.nvim_create_namespace("config.editor")
local sb = require("string.buffer")
local utils = require("config.utils")

local M = {}

-- how long to wait until clearing the key history
local KEYHIST_TIMEOUT = 2e9 -- 2 seconds

local key_hist = sb.new(4096)
local last_key_time = 0
vim.on_key(function(key, typed)
    local time = vim.uv.hrtime()
    if time - last_key_time > KEYHIST_TIMEOUT then
        key_hist:reset()
    end
    last_key_time = time
    key_hist:put(typed)
end, ns)

M.get_key_history = function()
    return key_hist:tostring()
end

---@type table<string, fun(url: string): string?, string?, integer?, integer?>
local url_transforms = {
    -- use raw versions for files from github
    ["https://github.com"] = function(url)
        local suburl = url:gsub("^https://github%.com/", "")
        local repo = suburl:match("([^/]+/[^/]+)")
        local path = repo and suburl:sub(#repo) or ""

        if suburl == repo then           -- README for plain repo
            return ("https://raw.githubusercontent.com/%s/master/README.md"):format(suburl), "README.md"
        elseif path:match("/blob/") then -- files
            local raw = url:gsub("github%.com", "raw.githubusercontent.com"):gsub("/blob/", "/")
            local filepart = url:match("/([^/]*)$")
            local parts = vim.split(filepart, "?")

            local startline, endline
            if parts then
                local args = vim.split(parts[2], "#")
                for _, arg in ipairs(args) do
                    local start, stop = arg:match("L(%d+)%-?L?(%d*)")
                    startline = start and tonumber(start) or nil
                    endline = stop and tonumber(stop) or nil
                end
            end

            return raw, parts[1], startline, endline
        end
    end,
}

Jhk.WebIncludeExpr = function()
    local path = vim.v.fname
    local base_url = api.nvim_buf_get_name(0)
    return base_url .. path
end

---@param ev vim.api.keyset.create_autocmd.callback_args
M.view_web = function(ev)
    local buf = ev.buf
    local bo = vim.bo[buf]
    bo.swapfile = false
    bo.undofile = false

    local url = api.nvim_buf_get_name(buf):gsub("/$", "")
    local range, name
    api.nvim_buf_set_name(buf, url) -- normalize URLs ending in /
    for pattern, transform in pairs(url_transforms) do
        if vim.startswith(url, pattern) then
            local res, file, startline, endline = transform(url)
            if res then
                url = res
                range = { startline, endline }
                name = file
                break
            end
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
                ft = vim.filetype.match { filename = name or url }
            end
        end

        utils.buf_drop_undo(buf)

        if range[1] then
            api.nvim_win_set_cursor(0, { range[1], 0 })
            if range[2] then
                vim.cmd.normal { "V", bang = true }
                api.nvim_win_set_cursor(0, { range[2], 0 })
            end
        end

        bo.filetype = ft or "html"
        bo.modified = false
        bo.buftype = "nowrite"

        -- resolve paths relative to the site
        bo.includeexpr = "v:lua.Jhk.WebIncludeExpr()"
    end))
end

return M
