local M = {}

--[[ Description {{{
Synkit (syn-kit or sync-it) is a way to write classic vim syntax files in lua
by simply specifying the syntax as a set of strings and tables.

TODO: Grouping
}}} ]]
-- Types {{{
---@alias synkit.DetailedMatch {[1]: string, conceal: string?, spell: boolean?, contained: boolean, containedin: string[]}
---@alias synkit.Match (string|synkit.DetailedMatch)
---@alias synkit.Keyword string|{[integer]: string, conceal: string?}
---@alias synkit.Region {start: string, stop: string, skip: string?, contains: string[]?, extra: string?}

---@alias synkit.MatchEntry {[integer]: synkit.Match, priority: integer?}

---@alias synkit.Matches table<string, synkit.MatchEntry>
---@alias synkit.Keywords table<string, synkit.Keyword[]>
---@alias synkit.Regions table<string, synkit.Region>


---@class synkit.Syntax
---@field name string
---@field iskeyword string?
---@field keywords synkit.Keywords
---@field match synkit.Matches
---@field regions synkit.Regions

-- }}}

local title = function(s)
    return s:sub(1, 1):upper() .. s:sub(2)
end

local tosyngroup = function(g)
    return table.concat(vim.tbl_map(title, vim.split(g, "%.")))
end


---@param syn string
---@param group string
---@param do_link fun(from: string, to: string)
local mkname = function(syn, group, do_link)
    local g = syn .. tosyngroup(group)
    do_link(g, ("@%s.%s"):format(group, syn))
    return g
end

---@param env synkit.SynCallbacks
local mklist = function(name, list, env)
    return table.concat(vim.tbl_map(function(c)
        return mkname(name, c, env.link_hl)
    end, list), ",")
end

---@param syn synkit.Syntax
---@param pattern synkit.DetailedMatch
---@param env synkit.SynCallbacks
local mksuffix = function(syn, pattern, env)
    local suffix = {}
    if pattern.spell then
        table.insert(suffix, "contains=@Spell")
    end
    if pattern.conceal then
        table.insert(suffix, "conceal cchar=" .. pattern.conceal)
    end
    if pattern.contained then
        table.insert(suffix, "contained")
    end
    if pattern.containedin then
        table.insert(suffix, "containedin=" .. mklist(syn.name, pattern.containedin, env))
    end

    return table.concat(suffix, " ")
end

---@param group string
---@param spec string
---@param do_syn fun(string)
local match = function(group, spec, suffix, do_syn)
    do_syn(("match %s '%s' %s"):format(group, spec:gsub("'", "\\'"), suffix))
end

---@param do_syn fun(string)
local keyword = function(group, word, suffix, do_syn)
    do_syn(("keyword %s %s %s"):format(group, word, suffix))
end

---@return string[]
local expand_string_pattern = function(patterns)
    return vim.tbl_filter(function(ptrn)
        return #ptrn > 0
    end, vim.tbl_map(vim.trim, vim.split(patterns, "%s")))
end

---@param list synkit.Keyword[]
---@param group string
---@param env synkit.SynCallbacks
local do_keywd_list = function(list, group, env)
    local items, suffix
    for _, word in ipairs(list) do
        if type(word) == "table" then
            suffix = word.conceal and "conceal cchar=" .. word.conceal or ""
            items = word
        else
            suffix = ""
            items = { word }
        end

        for _, w in ipairs(items) do
            keyword(group, w, suffix, env.syntax)
        end
    end
end

---@class synkit.SynCallbacks
---@field syntax fun(cmd: string) Call a syntax command
---@field set fun(opt: string, val: string) Set a buffer-local option
---@field link_hl fun(from: string, to: string)

---@param syn synkit.Syntax
---@param env synkit.SynCallbacks
local do_set_syntax = function(syn, env)
    if syn.iskeyword then
        env.set("iskeyword", syn.iskeyword)
    end

    for group, words in pairs(syn.keywords) do
        if type(group) == "string" then
            do_keywd_list(words, mkname(syn.name, group, env.link_hl), env)
        end
    end

    for reg, region in pairs(syn.regions) do
        local extra = {
            region.skip and "skip=+" .. region.skip .. "+",
        }

        if region.contains then
            local contains = mklist(syn.name, region.contains, env)
            table.insert(extra, "contains=" .. contains)
        end
        env.syntax(("region %s start=+%s+ end=+%s+ %s %s"):format(
            mkname(syn.name, reg, env.link_hl),
            region.start,
            region.stop,
            table.concat(extra, " "),
            region.extra or ""
        ))
    end

    local groups = vim.tbl_keys(syn.match)
    table.sort(groups, function(a, b)
        local enta = syn.match[a]
        local entb = syn.match[b]
        local prioa = (type(enta) == "table" and enta.priority) or 0
        local priob = (type(entb) == "table" and entb.priority) or 0

        return prioa < priob
    end)
    for _, group in ipairs(groups) do
        local gname = mkname(syn.name, group, env.link_hl)
        local patterns = syn.match[group]

        for _, pattern in ipairs(patterns) do
            local list, suffix
            if type(pattern) == "table" then
                ---@cast pattern string[]
                list = pattern
                suffix = mksuffix(syn, pattern, env)
            else
                list = expand_string_pattern(pattern)
                suffix = ""
            end

            for _, rx in ipairs(list) do
                match(gname, rx, suffix, env.syntax)
            end
        end
    end
end


---@param syn synkit.Syntax
M.syntax = function(syn)
    if vim.b.current_syntax then
        return
    end
    vim.b.current_syntax = syn.name

    local groups_done = {}
    do_set_syntax(syn, {
        syntax = vim.cmd.syntax,
        set = function(opt, val)
            vim.bo[opt] = val
        end,
        link_hl = function(from, to)
            if not groups_done[from] then
                vim.api.nvim_set_hl(0, from, { link = to })
                groups_done[from] = true
            end
        end
    })

    vim.api.nvim_buf_create_user_command(0, "SynkitExport", function(args)
        M.export(syn, args.args)
    end, {
        complete = "file",
        nargs = 1
    })
end

---@param syn synkit.Syntax
---@param file string
M.export = function(syn, file)
    local lines = {
        [[" This syntax file was generated using synkit]],
        [[" It is NOT meant for manual editing]],
        [[" Creation date: ]] .. os.date("%Y-%m-%d")
    }

    local syns = { "", [[" Syntax definitions:]] }
    local lets = { "", [[" Local Variables:]] }
    local links = { "", [[" Highlight Group Links:]] }
    do_set_syntax(syn, {
        syntax = function(args)
            table.insert(syns, ("syntax %s"):format(args))
        end,
        set = function(key, val)
            table.insert(lets, ("let &l:%s = \"%s\""):format(key, val:gsub([=[[\"]]=], "\\%1")))
        end,
        link_hl = function(from, to)
            table.insert(links, ("highlight link %s %s"):format(from, to))
        end
    })

    vim.list_extend(lines, lets)
    vim.list_extend(lines, syns)
    vim.list_extend(lines, links)
    local text = table.concat(lines, "\n")

    vim.uv.fs_open(file, "w", 420, function(err, fd)
        if err then
            require("config.utils").error("Synkit", err)
            return
        end

        vim.uv.fs_write(fd, text)

        vim.uv.fs_close(fd)
    end)
end

return M
