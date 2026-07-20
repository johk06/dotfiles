local utils = require("config.utils")
local A = utils.A
local buf = vim.api.nvim_get_current_buf()
local bo = vim.bo[buf]
local wo = vim.wo[0][0]
bo.textwidth = 90
wo.conceallevel = 2

local preview = require "config.plugins.typst-preview"

vim.b.build_output = {
    kind = "ext",
    action = "open",
    value = "pdf"
}

-- Get spelling from option {{{
-- e.g. `#set text(lang: "de")`
local QUERY = [[; query
(set
  (call
    item: (_) @_name
    (group
      (tagged
        field: (ident) @_field
        (string) @value))
    (#eq? @_name "text")
    (#eq? @_field "lang")))
]]

local parser = vim.treesitter.get_parser(buf, "typst")
if parser then
    parser:parse()
    local tree = assert(parser, "Failed to create treesitter parser"):trees()[1]
    local parsed = vim.treesitter.query.parse("typst", QUERY)
    for id, node, _ in parsed:iter_captures(tree:root(), buf) do
        if parsed.captures[id] == "value" then
            local text = vim.treesitter.get_node_text(node, buf)
            bo.spelllang = text:sub(2, -2) -- remove quotes
            break
        end
    end
end
-- }}}

local map = require("config.utils").ft_mapper()
-- Previews {{{
map("n", "<localleader>p", function()
    preview.attach(0, {})
    preview.open()
end, { desc = "Typst: Preview" })

map("n", "<localleader>s", function()
    preview.toggle_scroll(0)
end)
-- }}}

-- Quick equations
map("n", "<localleader>e", A { "\\$", "\t$0", "\\$", "" }, { desc = "Typst: Equation" })
map("n", "<localleader>E", A { "\\$", "\t$0", "\\$ <$1>", "" }, { desc = "Typst: Labelled Equation" })

-- Quick inline formatting
map("i", "<M-e>", A [[\$$1\$ $0]])

map("n", "<localleader>h", function()
    require("telescope.builtin").lsp_document_symbols {
        symbols = { "namespace" }
    }
end, { desc = "Typst: List Headings" })

map("n", "<localleader>r", function()
    require("telescope.builtin").lsp_document_symbols {
        symbols = { "constant" }
    }
end, { desc = "Typst: List References" })

local fwd_heading, bwd_heading = utils.movement_pair(function(fwd)
    vim.fn.search([[^\s*=]], "s" .. (fwd and "" or "b"))
end)
map("n", "]]", fwd_heading)
map("n", "[[", bwd_heading)
