local utils = require "config.utils"
--[[ Replacement for spellfile.vim {{{
Partially replicate what spellfile.vim does, just in a more modern way

Why? spellfile.vim relies on netrw, is written in vimscript and is not that readable
}}} ]]

-- use the same mirror spellfile.vim uses
local spell_file_url = "https://ftp.nluug.nl/pub/vim/runtime/spell/"

local spellfile_donwload_dir = vim.tbl_map(function(dir)
    local spelldir = dir .. "/spell"
    if vim.uv.fs_access(spelldir, "W") and vim.uv.fs_stat(spelldir).type == "directory" then
        return spelldir .. "/"
    end
end, vim.opt.runtimepath:get())[1]

local M = {}
local api = vim.api

local download_spellfile = function(lang)
    -- utf-8 is the only real modern encoding
    local name = lang .. ".utf-8"

    local spl = name .. ".spl"
    local sug = name .. ".sug"
    local splpath = spellfile_donwload_dir .. spl
    local sugpath = spellfile_donwload_dir .. sug

    vim.system({
        "curl", "--fail", "--no-progress-meter", "--parallel",
        spell_file_url .. spl, "--output", splpath,
        spell_file_url .. sug, "--output", sugpath,
    }, {}, function(res)
        if res.code ~= 0 then
            vim.uv.fs_unlink(splpath)
            vim.uv.fs_unlink(sugpath)

            vim.schedule(function()
                utils.error("Spell", "Failed to get spellfiles for " .. lang)
            end)
        else
            vim.schedule(function()
                utils.message("Spell", "Fetched " .. lang)
            end)
        end
    end)
end

M.tried_languages = {}
local try_to_download = function(name)
    if M.tried_languages[name] then
        print("Already tried to get language: " .. name)
        return
    end
    print("Language not found: " .. name .. ", trying to download...")
    M.tried_languages[name] = true
    download_spellfile(name)
end

api.nvim_create_autocmd("SpellFileMissing", {
    callback = function(ev)
        try_to_download(ev.match)
    end
})

return M
