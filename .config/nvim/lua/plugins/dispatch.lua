--[[ Why something so old? {{{
 It isn't written in lua, it's not that fast &c.
 But it does very little.
 "Modern" alternatives like https://github.com/stevearc/overseer.nvim do
 everything up to and including parsing Microsoft's weird build specification.
 Additionally they have various new pieces of UI that do not necessarily make
 sense with my approach. (Task lists, "editors" and other things)
 They also do not interact with Vim primitives by default.

 In contrast, this like basically all tpope-plugins is deceptively simple and
 tries to be very close to Vim builtins. There are some unnecessary
 abstractions like :Start and :Spawn, that are due to history and are not
 necessary anymore, but I do not have to use those.
 Dispatch does nothing more but populate the quickfix list asynchronously for me.

 If I need a seriously complicated command, just using the shell is easier than
 learning a new interface.

 Keymaps: *two* leader keys
 - <space>m (<space>M reserved) to just compile
 - <space>b to do more: e.g. <space>bo - build output

 Basic workflow:
 - <space>m to build basically anything, when using make adding a v:count makes it clean first
 - If I am interested in the output: <space>bo
}}}]]

local api = vim.api
local utils = require("config.utils")
local M = {
    "tpope/vim-dispatch"
}

---@class config.BuildOutputSpec
---@field kind "ext"|"path"
---@field action "open"|"exec"
---@field value string

local compiler_is_make = function()
    return vim.o.makeprg == "make"
end

local if_make = function(cmd)
    return function()
        if compiler_is_make() then
            vim.cmd.Make { bang = true, cmd }
        else
            utils.warn("Dispatch", ("Not using make(1), `make %s` is not useful"):format(cmd))
        end
    end
end

M.init = function()
    vim.g.dispatch_no_maps = true
    vim.g.dispatch_compilers = {
        bear = "gcc"
    }

    local map = function(key, cmd, desc)
        utils.map("n", "<space>b" .. key, cmd, { desc = ("Build: %s"):format(desc) })
    end

    -- Useful to make a different target, e.g. <space>bi debug<cr>
    map("i", ":Make<space>", "(input)")

    utils.map("n", "<space>M", ":Make<space>", { desc = "Build: (input)" })

    -- Run an arbitrary command as a job
    map("d", ":Dispatch<space>", "Dispatch")

    -- Cancel the current command
    map("a", "<cmd>AbortDispatch<cr>", "Abort")
    -- Cancel any command by name
    map("A", ":AbortDispatch<space>", "Abort (input)")

    -- This primarily makes sense for Makefiles ofc, other build systems won't always have that
    map("c", if_make("clean"), "Clean")
    map("I", if_make("install"), "Install")

    -- Open the current output; NOTE: <space>m hides it by default
    map("o", "<cmd>Copen<cr>", "Open")

    -- Do not hide the output
    map("v", "<cmd>Make<cr>", "Verbose")

    map("j", function()
        local ft = vim.bo.ft
        local makeprg = vim.o.makeprg

        if (ft == "c" or ft == "cpp") then
            if compiler_is_make() then
                vim.cmd.Make { "clean", bang = true }
            end
            vim.cmd.Dispatch { "bear", "--", makeprg, bang = true }
        else
            utils.warn("Dispatch", "It seems you're not using C(++), bear would be pointless")
        end
    end, "Generate compile_commands.json")

    --[[ Be as smart as possible. If we are using makefiles and have a count, rebuild it
     Write the current file to disk (if I don't want this, I can just use :Make)
     Does *not* show output live (too distracting usually), :Copen can be
     used during compilation too ]]
    utils.map("n", "<space>m", function()
        if compiler_is_make() and vim.v.count ~= 0 then
            vim.cmd.Make { "clean", bang = true }
        end
        vim.cmd.update()
        vim.cmd.Make { bang = true }
    end, { desc = "Make: do what I mean" })

    --[[ Part of the classic Compile-Run cycle is actually starting the result
      This mapping allows that to be much smarter
      Buffer overrides Tab overrides Global here
      Ftplugins should set b: ]]
    map("r", function()
        ---@type config.BuildOutputSpec
        local ospec = vim.b.build_output or vim.t.build_output or vim.g.build_output
        if not ospec then
            utils.error("Dispatch", "No b:build_output, cannot determine what file to open")
            return
        end

        local path

        if ospec.kind == "ext" then
            path = ("%s.%s"):format(vim.fn.expand("%:r"), ospec.value)
        elseif ospec.kind == "path" then
            path = ospec.value
        end

        if ospec.action == "open" then
            vim.ui.open(path)
        elseif ospec.action == "exec" then
            vim.cmd.Start(path)
        end
    end, "Open Result")

    -- Set b: or t:build_output
    api.nvim_create_user_command("Target", function(args)
        local target = args.args

        local is_exec
        if args.count ~= 0 then
            is_exec = true
        end

        local st, _ = vim.uv.fs_stat(target)
        if st then
            if bit.band(st.mode, 73 --[[0111]]) ~= 0 then
                is_exec = true
            end
        end

        ---@type config.BuildOutputSpec
        local spec = {
            value = vim.fs.abspath(args.args),
            kind = "path",
            action = is_exec and "exec" or "open"
        }

        if args.bang then
            vim.t.build_output = spec
        else
            vim.b.build_output = spec
        end
    end, { bang = true, nargs = 1, complete = "file", count = 0, desc = "Target file as default to run" })

    map("t", ":Target<space>", "Set Target")
end

return M
