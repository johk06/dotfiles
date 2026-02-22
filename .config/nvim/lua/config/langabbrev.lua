--[[ Synopsis {{{
 A vim-abolish like way to define tons of abbreviations at once
 The main difference to tpope's venerable plugin is that this is all in lua and
 does not expose a command to create them on the fly (yet).
 The abbreviations are loaded similarly to my blink snippets based on spelllang
 from the runtimepath.
 When 'spl' changes, the snippets are adjusted
}}} ]]

local M = {}

local empty_map = { [""] = "" }
local toupper = vim.fn.toupper
local utils = require("config.utils")

local title = function(s)
    local i = 1
    local u
    while i <= #s do
        local c = s:sub(i, i)
        u = toupper(c)
        if c ~= u then
            break
        end

        i = i + 1
    end
    return s:sub(1, i - 1) .. u .. s:sub(i + 1)
end
M.title = title

---@class config.AbbrevSpec
---@field [1] string
---@field [2] string
---@field prefixes table<string, string>?
---@field suffixes table<string, string>?
---@field case_variants boolean?

---@param spec config.AbbrevSpec
---@param dest [string, string][]
M.compile = function(spec, dest)
    for p, prfx in pairs(spec.prefixes or empty_map) do
        prfx = prfx or p
        for s, sufx in pairs(spec.suffixes or empty_map) do
            sufx = sufx or s
            local abbr = p .. spec[1] .. s
            local expn = prfx .. spec[2] .. sufx
            table.insert(dest, { abbr, expn })
            if spec.case_variants then
                table.insert(dest, { title(abbr), title(expn) })
            end
        end
    end
end

---@param specs config.AbbrevSpec[]
---@return [string, string][]
M.compile_specs = function(specs)
    local res = {}

    for _, spec in ipairs(specs) do
        M.compile(spec, res)
    end

    return res
end

---@type table<string, [string, string][]>
local compiled = {}

local get_abbrevs_for_lang = function(lang)
    if not compiled[lang] then
        local luafile = vim.api.nvim_get_runtime_file(("abbrev/%s.lua"):format(lang), false)[1]
        if not luafile then
            compiled[lang] = {}
        else
            local ok, spec_or_err = pcall(dofile, luafile)
            if not ok then
                utils.error("Abbrev", ("Failed to load: %s"):format(spec_or_err))
                compiled[lang] = {}
            else
                compiled[lang] = M.compile_specs(spec_or_err)
            end
        end
    end

    return compiled[lang]
end

local on_spl_set = function(ev)
    local buf = ev.buf or vim.api.nvim_get_current_buf()
    local old_lang = vim.v.option_old
    local new_lang = vim.v.option_new or vim.bo.spelllang

    local old_abbrevs = get_abbrevs_for_lang(old_lang)
    if old_abbrevs then
        for _, map in ipairs(old_abbrevs) do
            pcall(vim.keymap.del, "ia", map[1], { buffer = buf })
        end
    end

    local new_abbrevs = get_abbrevs_for_lang(new_lang)
    if new_abbrevs then
        for _, map in ipairs(new_abbrevs) do
            vim.keymap.set("ia", map[1], map[2], { buffer = buf })
        end
    end
end

require("config.utils").autogroup("config.abbreviations", {
    OptionSet = {
        pattern = "spelllang",
        callback = on_spl_set
    },
})

return M
