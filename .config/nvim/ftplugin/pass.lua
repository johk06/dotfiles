local api = vim.api
local lo = vim.opt_local
local go = vim.o

local buf = api.nvim_get_current_buf()
local bname = api.nvim_buf_get_name(buf)
local short_name = bname:match("/dev/shm/pass%..-/.-%-(.-)%.txt")
vim.b[buf].special_bufname = ("pass:%s"):format(short_name:gsub("-", "/"))

-- No data shall leave the buffer
go.backup = false
go.writebackup = false
go.swapfile = false
go.shada = ""
go.undofile = false

lo.conceallevel = 2
lo.concealcursor = "nc"
lo.wrap = false -- things like `otpauth://` URLs can be really long

local count = 0
local ns = api.nvim_create_namespace("config.password-store")
local current_concealed_passwd_id

local REDACTED_MESSAGE = "Password Redacted: "

local conceal_passwd = function(w)
    local mode = api.nvim_get_mode().mode


    if (mode == "n" or mode == "c") and vim.wo[w].conceallevel > 0 then
        local txt = api.nvim_buf_get_lines(buf, 0, 1, false)[1]
        local passwdlen = #txt -- assume password is ASCII
        if passwdlen == 0 then
            return
        end

        local charcount_hl
        if passwdlen < 12 then
            charcount_hl = "DiagnosticError"
        elseif passwdlen < 24 then
            charcount_hl = "DiagnosticWarn"
        elseif passwdlen < 32 then
            charcount_hl = "DiagnosticHint"
        else
            charcount_hl = "DiagnosticOk"
        end

        local charcount = ("%d chars"):format(passwdlen)
        local virt_text = { { REDACTED_MESSAGE, "@comment" }, { charcount, charcount_hl } }

        count = count + 1
        current_concealed_passwd_id = api.nvim_buf_set_extmark(buf, ns, 0, 0, {
            id = current_concealed_passwd_id,
            virt_text = virt_text,
            hl_group = "Hidden",
            hl_eol = true,
            end_row = 1,
            virt_text_win_col = 0,
        })
        return false
    else
        if current_concealed_passwd_id then
            api.nvim_buf_del_extmark(buf, ns, current_concealed_passwd_id)
            current_concealed_passwd_id = nil
        end
        return false
    end
end

api.nvim_set_decoration_provider(ns, {
    on_win = function(_, w, b, top, btm)
        if b ~= buf then
            return false
        end

        if top == 0 then
            return conceal_passwd(w)
        end

        return true
    end
})

vim.defer_fn(function()
    require("config.utils").warn(
        "Pass",
        "Editing a password-store file, increasing security"
    )
end, 10)

local map = require("config.utils").local_mapper(buf)
