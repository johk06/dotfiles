local utils = require("config.utils")
---@type LazySpec
local M = {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
        {
            "<space>p",
            function()
                require("conform").format { async = true }
            end,
            mode = { "n", "x" },
        },
    },
}

---@type conform.setupOpts
M.opts = {
    formatters_by_ft = {
        _     = { "trim_whitespace", "injected", lsp_format = "last" },
        c     = { "clang-format" },
        go    = { "gofmt" },
        json  = { "jq" },
        query = { "format-queries" },
        sh    = { "shfmt" },
        toml  = { "taplo" },
        typst = { "prettypst" },
        xml   = { "xmllint" },
    },
    default_format_opts = {
        lsp_format = "fallback",
    },
    formatters = {
        jq = {
            inherit = true,
            -- make jq respect shiftwidth
            append_args = function(_, ctx)
                if vim.bo[ctx.buf].expandtab then
                    local width = ctx.shiftwidth
                    if width > 7 then
                        utils.warn("Conform", "Jq only supports up to 7 spaces indent, reducing to 7")
                        width = 7
                    end
                    return { "--indent", tostring(width) }
                else
                    return { "--tab" }
                end
            end
        },
        taplo = {
            inherit = true,
            append_args = function(_, ctx)
                local indent
                if vim.bo[ctx.buf].expandtab then
                    indent = (" "):rep(ctx.shiftwidth)
                else
                    indent = "\t"
                end

                return { "-o", "indent_string=" .. indent }
            end
        },
        xmllint = {
            inherit = true,
            env = function(_, ctx)
                if vim.bo[ctx.buf].expandtab then
                    return {
                        XMLLINT_INDENT = (" "):rep(ctx.shiftwidth)
                    }
                else
                    return {}
                end
            end
        }
    }
}

return M
