vim.cmd.compiler("gcc")

vim.b.snippets = {
    f = {
        "${1:void} ${2:name}($3) {",
        "    $0",
        "}"
    }
}
