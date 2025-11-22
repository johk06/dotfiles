--[[
My *third* attempt at a handcrafted dashboard
This mostly allows me to quickly open a previous file or project
with [count](o|p), and quickly perform other common tasks.

Additionally, and perhaps more importantly, it's also pretty eye candy.
]]

-- Configuration Variables {{{
local MAX_OLDFILES = 32
local MAX_PROJECTS = 8
local MESSAGES = {
    ":%s/emacs/vim/g",
    ":3 is a valid ex command, and you're valid too 🏳️‍⚧️",
    ":find is often faster than :e",
    "All your issues are only in your :cwindow",
    "Enjoy your day!",
    "Gæð á wyrd swá heó sċeall",
    "Hiġe sċeall þé headra, heorte þé cénre, mód sċeall þé mære, þé úre mæġen lýtlað.",
    "It is our duty to keep computing gay, we owe that to Turing",
    "Never :q me for emacs",
    "Tired? Just <C-z>",
}
---@type ({[1]: string, desc: string, key: string, on_click: function, hl: string})[]
local ACTIONS = {
    {
        "Edit new File",
        desc = "New File",
        key = "e",
        on_click = vim.cmd.enew,
        hl = "EditFile"
    },
    {
        "Search/Grep",
        desc = "Search by file content",
        key = "s",
        on_click = function()
            require("telescope.builtin").live_grep()
        end,
        hl = "GrepFiles"
    },
    {
        "Find Files",
        desc = "Search by file name",
        key = "f",
        on_click = function()
            require("telescope.builtin").find_files()
        end,
        hl = "FindFiles"
    },
    {
        "View Filesystem",
        desc = "Edit filesystem as buffer",
        key = "v",
        on_click = function()
            require("oil").open()
        end,
        hl = "EditFiles"
    },
    {
        "Agenda",
        desc = "Show current org agenda",
        key = "a",
        on_click = function()
            Org.agenda.a()
        end,
        hl = "Agenda"
    },
    {
        "Capture",
        desc = "Capture note using org",
        key = "w",
        on_click = function()
            Org.capture()
        end,
        hl = "Capture"
    },
    {
        "Plugins",
        desc = "Use Lazy",
        key = "L",
        on_click = vim.cmd.Lazy,
        hl = "Lazy"
    },
    {
        "Packages",
        desc = "Manage using Mason",
        key = "M",
        on_click = vim.cmd.Mason,
        hl = "Mason"
    },
    {
        "Quit NeoVIM",
        desc = "Goodbye, yes it's possible",
        key = "q",
        on_click = vim.cmd.quit,
        hl = "Quit"
    }
}
-- }}}

local fn = vim.fn
local uv = vim.uv
local api = vim.api
local ns = api.nvim_create_namespace("config.dashboard")
local utils = require("config.utils")

---@class dashboard.entry
---@field left ([string, string])[]
---@field right ([string, string])[]
---@field data table
---@field callback fun()
---@field map string?

---@class dashboard.section
---@field title string
---@field titlehl string
---@field map string?
---@field items dashboard.entry[]

-- Helpers {{{
local State = {
}

local strwidth = require("plenary.strings").strdisplaywidth

local linewidth = function(line)
    local width = 0
    for _, chunk in pairs(line) do
        width = width + strwidth(chunk[1])
    end

    return width
end

local take_lines = function(count)
    State.drawable = State.drawable - count
end

local advance_lines = function(count)
    State.current = State.current + count
    take_lines(count)
end

local insert_empty = function(count)
    local lines = {}
    for _ = 1, count do
        table.insert(lines, "")
    end

    api.nvim_buf_set_lines(State.buf, State.current, State.current, false, lines)
    advance_lines(count)
end

---@param row integer
---@param col integer
---@param mark vim.api.keyset.set_extmark
local set_extmark = function(row, col, mark)
    api.nvim_buf_set_extmark(State.buf, ns, row, col, mark)
end

local set_virt_lines = function(row, lines, before)
    set_extmark(row, 0, {
        virt_lines_above = before,
        virt_lines = lines
    })
    take_lines(#lines)
end

local get_center_padding = function(width)
    return math.floor((State.width - width) / 2)
end

local get_center_spaces = function(width)
    return (" "):rep(get_center_padding(width))
end

local insert_text = function(lines)
    local text = vim.tbl_map(function(line)
        return table.concat(vim.tbl_map(function(chunk)
            return chunk[1]
        end, line))
    end, lines)

    api.nvim_buf_set_lines(State.buf, State.current, State.current + #lines, false, text)

    for i, line in ipairs(lines) do
        local acc = 0
        for _, chunk in ipairs(line) do
            local endcol = acc + #chunk[1]
            set_extmark(State.current + i - 1, acc, {
                hl_group = chunk[2],
                end_col = endcol,
            })
            acc = endcol
        end
    end

    advance_lines(#lines)
end
-- }}}

-- Data {{{
local Letters = vim.tbl_map(function(row)
    local elements = { "" } -- leave one element to cheaply insert padding
    for i = 1, #row do
        table.insert(elements, { row[i], "DashboardTitle" .. i })
    end
    return elements
end, {
    ---@format disable
    {"      ████ ██████","          ",""," █████      ","██ ","                 "},
    {"     ███████████","         ","   "," █████    ","      ","                "},
    {"     █████████"," ████████","███","████████ ","███ ","  ███████████"},
    {"    █████████","  ███    ","█████","████████ ","█████"," ██████████████"},
    {"   █████████"," ████████","██ ██","███████ ","█████"," █████ ████ █████"},
    {" ███████████"," ███    ","███ ███","██████ ","█████"," █████ ████ █████"},
    {"██████  ███","█████████","█████████"," ████ ","█████"," █████ ████ ██████"},
    ---@format enable
})
local LETTER_WIDTH = 70
-- }}}

---@type dashboard.section
local ProjectSection = {
    title = "Projects",
    titlehl = "DashboardProjects",
    map = "p",
    items = {}
}
do
    local workspaces = require("projections.workspace")
    local switcher = require("projections.switcher")
    local sessions = require("projections.session")

    for _, ws in ipairs(workspaces.get_workspaces()) do
        local projects = ws:projects()
        for _, proj in pairs(projects) do
            local name = proj.name
            local path = ws.path.path .. "/" .. proj.name
            local head = utils.expand_home(fn.fnamemodify(path, ":h"), 8) .. "/"

            local session = sessions.info(path)
            local mtime
            local last_access = { "(Not yet opened)", "Comment" }
            if session and session.path then
                local st = uv.fs_stat(session.path.path)
                if st then
                    mtime = st.mtime.sec
                    local date = utils.datefmt.fmt_short(mtime)
                    local datehl = utils.highlight_time(mtime)

                    last_access = { date, datehl }
                end
            end

            table.insert(ProjectSection.items, {
                left = { nil, { head, "NonText" }, { name, "Identifier" } },
                right = { last_access },
                data = { mtime = mtime or 0 },
                callback = function()
                    switcher.switch(path)
                end
            })
        end
    end

    table.sort(ProjectSection.items, function(p1, p2)
        return p1.data.mtime > p2.data.mtime
    end)
    if #ProjectSection.items > MAX_PROJECTS then
        ProjectSection.items[MAX_PROJECTS + 1] = nil -- HACKY: protect from ipairs
    end

    for i, proj in ipairs(ProjectSection.items) do
        proj.left[1] = { ("%2d. "):format(i - 1), "Number" }
    end
end

---@type dashboard.section
local OldfileSection = {
    title = "Old Files",
    titlehl = "DashboardRecents",
    map = "o",
    items = {}
}
do
    local helpdir = vim.env.VIMRUNTIME .. "/doc/"
    local index = 0
    for _, file in ipairs(vim.v.oldfiles) do
        if index > MAX_OLDFILES then
            break
        end

        -- ignore :h
        if vim.startswith(file, helpdir) then
            goto continue
        end

        local is_oil = vim.startswith(file, "oil://")
        local highlight
        if is_oil then
            file = file:sub(7, -2)
            highlight = "Directory"
        end
        local st = vim.uv.fs_stat(file)
        if st then
            if not highlight then
                highlight = utils.highlight_fname(file)
            end

            local mtime = st.mtime.sec
            local timestring = utils.datefmt.fmt_short(mtime)
            local timehl = utils.highlight_time(mtime)

            local tail = fn.fnamemodify(file, ":t")
            local head = utils.expand_home(fn.fnamemodify(file, ":h"), 2)
            if head ~= "/" then
                head = head .. "/"
            end

            table.insert(OldfileSection.items, {
                data = {},
                left = { { ("%2d. "):format(index), "Number" }, { head, "NonText" }, { tail, highlight } },
                right = { { timestring, timehl } },
                callback = function()
                    vim.cmd.edit(file)
                end
            })

            index = index + 1
        end

        ::continue::
    end
end

---@type dashboard.section
local ActionSection = {
    title = "Quick Actions",
    titlehl = "DashboardActions",
    items = {}
}
do
    for _, action in ipairs(ACTIONS) do
        table.insert(ActionSection.items, {
            map = action.key,
            left = { { " " .. action.key .. " ", "SpecialChar" }, { action[1], "Dashboard" .. action.hl } },
            right = { { action.desc, "Comment" } },
            data = {},
            callback = action.on_click,
        })
    end
end

local Sections = {
    ActionSection,
    ProjectSection,
    OldfileSection
}

-- Drawing {{{
local draw_title = function()
    local spaces = get_center_spaces(LETTER_WIDTH)
    if State.drawable < #Letters or State.width < LETTER_WIDTH then
        return
    end

    for _, ltr in pairs(Letters) do
        ltr[1] = { spaces }
    end

    set_virt_lines(State.current, Letters)
end

local draw_lazy = function()
    local stats = require("lazy").stats()
    if not stats then
        return
    end

    local took_time = stats.times.LazyDone - stats.times.LazyStart
    local plugin_info = {
        { "" },
        { ("Loaded %d of %d plugins in "):format(stats.loaded, stats.count), "@comment" },
        { ("%.2fms"):format(took_time),                                      "@comment.note" },
        { " took ",                                                          "@comment" },
        { ("%.2fms"):format(stats.times.UIEnter or 0),                       "@comment.todo" },
        { " in total",                                                       "@comment" },
    }
    local padding = get_center_spaces(linewidth(plugin_info))
    plugin_info[1] = { padding }

    set_virt_lines(State.current, {
        { { "" } },
        plugin_info,
    })
end

local message_of_the_day = MESSAGES[(vim.fn.rand() % #MESSAGES) + 1]
local draw_message = function()
    local width = strwidth(message_of_the_day)

    set_virt_lines(State.current, {
        { { "" } },
        { { get_center_spaces(width) }, { message_of_the_day, "DashboardMessage" } }
    })
end

local draw_sections = function()
    local longest_line = 50
    for _, sec in pairs(Sections) do
        for _, line in pairs(sec.items) do
            local lwidth = linewidth(line.left)
            local rwidth = linewidth(line.right)

            local total_width = lwidth + rwidth
            line.data.lwidth = lwidth
            line.data.rwidth = rwidth
            line.data.width = total_width

            if total_width > longest_line then
                longest_line = total_width
            end
        end
    end

    longest_line = longest_line + 1
    local start_offset = get_center_padding(longest_line)
    State.col = start_offset - 1
    local initial_padding = (" "):rep(start_offset)

    for _, section in ipairs(Sections) do
        if #section.items == 0 then
            goto continue
        end

        local suffix = section.map and (" - [count]%s"):format(section.map) or ""
        local title = (" %s%s "):format(section.title, suffix)
        local titlewidth = strwidth(title)
        local remaining = State.width - titlewidth
        local half = math.floor(remaining / 2)

        if section.map then
            vim.keymap.set("n", section.map, function()
                local item = section.items[vim.v.count + 1]
                if item then
                    item.callback()
                end
            end, { buffer = State.buf })
        end

        table.insert(State.sections, { State.current, section })

        local left_padding = ("-"):rep(half)
        local right_padding = left_padding
        if remaining % 2 ~= 0 then
            right_padding = ("-"):rep(half + 1)
        end

        set_virt_lines(State.current - 1, {
            { { "" } },
            { { left_padding, "WinSeparator" }, { title, section.titlehl }, { right_padding, "WinSeparator" } }
        })

        local to_draw = {}
        for _, item in ipairs(section.items) do
            local center_padding = (" "):rep(longest_line - item.data.width)
            local line = { { initial_padding } }

            if item.map then
                vim.keymap.set("n", item.map, item.callback, { buffer = State.buf })
            end

            vim.list_extend(line, item.left)
            table.insert(line, { center_padding })
            vim.list_extend(line, item.right)
            table.insert(to_draw, line)
        end
        insert_text(to_draw)

        ::continue::
    end
end
-- }}}

local M = {}

local do_draw = function()
    local buf = State.buf
    vim.bo[buf].modifiable = true

    api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    api.nvim_buf_set_lines(buf, 0, -1, false, {})
    State.drawable = State.height
    State.current = 0
    State.sections = {}

    draw_title()
    draw_lazy()
    draw_message()
    advance_lines(1)
    insert_empty(1)
    State.row = State.current + 1
    draw_sections()

    vim.bo[buf].modifiable = false
end

local do_resize = function()
    State.width = api.nvim_win_get_width(State.win)
    State.height = api.nvim_win_get_height(State.win)
end

M.show = function()
    local buf = api.nvim_create_buf(false, true); State.buf = buf
    local win = api.nvim_get_current_win(); State.win = win

    local oldbuf = api.nvim_win_get_buf(0)
    api.nvim_win_set_buf(win, buf)
    api.nvim_buf_delete(oldbuf, { force = true })

    local wo = vim.wo[0][0]
    wo.number = false
    wo.relativenumber = false
    wo.foldenable = false
    wo.statuscolumn = ""
    wo.wrap = false

    local augroup
    augroup = utils.autogroup("config.dashboard", {
        WinResized = function()
            do_resize()
            do_draw()
        end,
        CursorMoved = function()
            local pos = api.nvim_win_get_cursor(win)
            if pos[1] <= State.row then
                pos[1] = State.row
            end

            if pos[2] ~= State.col then
                pos[2] = State.col
            end

            api.nvim_win_set_cursor(win, pos)
        end,
        [{ "BufWinLeave", "BufHidden" }] = function()
            api.nvim_del_augroup_by_id(augroup)
            vim.defer_fn(function()
                api.nvim_buf_delete(buf, { force = true })
            end, 10)
        end
    }, { buf = buf })


    api.nvim_create_autocmd("User", {
        pattern = "LazyLoad",
        group = augroup,
        callback = function()
            do_draw()
        end
    })

    local select_item = function(row)
        for i = #State.sections, 1, -1 do
            local section = State.sections[i]
            if section[1] < row then
                local offset = row - section[1]
                section[2].items[offset].callback()
                return
            end
        end
    end
    vim.keymap.set("n", "<cr>", function()
        select_item(api.nvim_win_get_cursor(0)[1])
    end, { buffer = buf })
    vim.keymap.set("n", "<LeftMouse>", function()
        local pos = vim.fn.getmousepos()
        select_item(pos.line)
    end, { buffer = buf })

    do_resize()
    do_draw()
end

return M
