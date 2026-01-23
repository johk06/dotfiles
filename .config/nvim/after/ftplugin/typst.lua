local buf = vim.api.nvim_get_current_buf()
vim.wo[0].conceallevel = 2

-- Get spelling from option {{{
-- e.g. `#set text(lang: "de")`
local QUERY = [[
;; query
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
            vim.bo[buf].spelllang = text:sub(2, -2) -- remove quotes
            break
        end
    end
end
-- }}}

if not vim.b[buf].did_preview then
    vim.cmd.TypstPreview()
    vim.b[buf].did_preview = true
end
