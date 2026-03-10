vim.bo.makeprg = "python %"

-- stolen from https://github.com/idbrii/vim-david/blob/main/compiler/python.vim
-- and converted to a more readable lua form
-- NOTE: ignore all the test-related stuff
vim.bo.errorformat = table.concat(vim.tbl_map(function(s)
    return s:gsub(",", "\\,")
end, {
    "%A%\\s%#File \"%f\", line %l, in%.%#",
    "%E File \"%f\" line %l",
    "%-C%p^", "%+C  %m", "%Z  %m"
}), ",")
