local M = {}

local org = require("orgmode")

---@type fun(data: OrgMenuData)
M.menu = function(data)
    local max_width = math.floor(vim.o.columns / 2)
    for _, item in ipairs(data.items) do
        local width = vim.fn.strdisplaywidth(item.label) + 2
        if width > max_width then
            max_width = width
        end
    end

    local keys = {}
    local buf = vim.api.nvim_create_buf(false, true)
    local items = {}
    for _, item in ipairs(data.items) do
        if item.key then
            keys[item.key] = item
            table.insert(items, ("%s %s"):format(item.key, item.label))
        end
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, items)
    local win = vim.api.nvim_open_win(buf, false, {
        title = data.title ~= data.prompt and ("%s - %s"):format(data.title, data.prompt) or data.title,
        title_pos = "center",
        style = "minimal",
        relative = "laststatus",
        anchor = "SW",
        col = 0,
        row = 0,
        width = max_width + 2,
        height = #items,
    })

    local ns = require("config.lib.ui").ns
    for i = 1, #items do
        vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, {
            end_line = i - 1,
            end_col = 1,
            hl_group = "SpecialChar",
        })
    end

    vim.cmd.redraw()
    local key = vim.fn.getcharstr(-1, { cursor = "hide" })
    vim.api.nvim_win_close(win, true)

    local entry = keys[key]
    if entry and entry.action then
        return entry.action()
    end
end

M.table_of_contents = function()
    local file = org.files:get_current_file()
    local buf = file:bufnr()
    local headlines = file:get_headlines()
    ---@type vim.quickfix.entry[]
    local entries = {}
    for _, headline in ipairs(headlines) do
        local level = headline:get_level()
        if level < 4 then
            local pos = headline:get_range()
            ---@type vim.quickfix.entry
            local entry = {
                lnum = pos.start_line,
                bufnr = buf,
                text = headline:get_title(),
            }
            table.insert(entries, entry)
        end
    end

    vim.fn.setloclist(0, entries)
    vim.cmd.lwin()
end

---@param targets vim.quickfix.entry[]
local jump_using_loclist = function(targets)
    if #targets == 0 then
        return
    end

    local buf = vim.api.nvim_get_current_buf()
    vim.cmd("normal! m'") -- set jump
    if #targets == 1 then
        local target = targets[1]
        if target.bufnr == buf then
            vim.api.nvim_win_set_cursor(0, { target.lnum, target.col - 1 })
        else
            local newbuf = target.bufnr or vim.fn.bufadd(target.filename)
            vim.api.nvim_win_set_buf(0, newbuf)
            vim.api.nvim_win_set_cursor(0, { target.lnum, target.col - 1 })
        end
        return
    end

    vim.fn.setloclist(0, targets)
    vim.cmd.lwin()
end

local select_buf_lines = function(predicate)
    local buf = vim.api.nvim_get_current_buf()

    local locations = {}
    local start_line = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    for i, line in ipairs(lines) do
        if i ~= start_line and predicate(line) then
            table.insert(locations, { lnum = i, col = 1, text = line, bufnr = buf })
        end
    end

    jump_using_loclist(locations)
end

---@type OrgLinkType
M.line_start_link = {
    get_name = function(self)
        return "line"
    end,
    follow = function(self, link)
        if not vim.startswith(link, "^:") then
            return false
        end

        local search = link:sub(3)
        select_buf_lines(function(line)
            return vim.startswith(line, search)
        end)

        return true
    end,
    autocomplete = function(self, link)
        if not vim.startswith(link.base, "^:") then
            return { "^:" }
        end

        local out = {}
        local search = link.base:gsub("^%^:", "")
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        for _, line in ipairs(lines) do
            if vim.startswith(line, search) then
                table.insert(out, "^:" .. line)
            end
        end
        return out
    end
}

---@type OrgLinkType
M.regex_search_link = {
    get_name = function(self)
        return "search"
    end,
    follow = function(self, link)
        if not vim.startswith(link, "?:") then
            return false
        end

        local regex = vim.regex(link:sub(3))

        select_buf_lines(function(line)
            return regex:match_str(line)
        end)

        return true
    end,
    autocomplete = function(self, link)
        return { "?:" }
    end
}

local complete_manpages = {}
vim.system({ "apropos", "." }, {
}, function(out)
    if out.stdout and out.code == 0 then
        local lines = vim.split(out.stdout, "\n")
        for _, l in ipairs(lines) do
            local name, sect = l:match("^(%S+)%s+(%(%d+%))")
            if name and sect then
                table.insert(complete_manpages, "man:" .. name .. sect)
            end
        end
    end
end)
---@type OrgLinkType
M.manpage_link = {
    get_name = function(self)
        return "manual"
    end,
    follow = function(self, link)
        if not vim.startswith(link, "man:") then
            return false
        end

        vim.cmd.Man(link:gsub("^man:", ""))

        return true
    end,
    autocomplete = function(self, link)
        if not vim.startswith(link.base, "man:") then
            return { "man:" }
            -- only complete after having typed two characters
        elseif #link.base > 5 then
            return complete_manpages
        else
            return {}
        end
    end,
}

---@type OrgCustomExport
M.typst_exporter = {
    label = "Export to Typst",
    ---@param export fun(command: string[], target: string)
    action = function(export)
        local file = vim.api.nvim_buf_get_name(0)
        local target = vim.fn.fnamemodify(file, ":p:r") .. ".typ"
        local command = { "pandoc", file, "-o", target }
        export(command, target)
    end
}

return M
