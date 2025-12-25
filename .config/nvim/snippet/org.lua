---@type config.SnippetConfig
return {
    schedule = {
        desc = "Add SCHEDULE and DEADLINE to heading",
        expand = function()
            local year = os.date("%Y")
            local today = os.date("%m-%d")
            return ("DEADLINE: <%s-${1:%s}> SCHEDULE: <%s-${2:%s}>"):format(year, today, year, today)
        end
    },
    man = {
        desc = "Link to manual page",
        expand = "[[man:${1}][$1]]",
    },
    example = {
        desc = "Example Block",
        expand = {
            "#+begin_example",
            "$0",
            "#+end_example"
        }
    },
    src = {
        desc = "Code Block",
        expand = {
            "#+begin_src ${1:lua}",
            "$0",
            "#+end_src"
        }
    },
    meta = {
        desc = "Document Metadata",
        expand = {
            "#+title: ${1}",
            "#+author: ${2}",
            "#+language: ${3:en}",
            "",
            "$0"
        }
    }
}
