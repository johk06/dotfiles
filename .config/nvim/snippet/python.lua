---@type config.SnippetConfig
return {
    math_boilerplate = {
        desc = "Stuff for math",
        expand = {
            "import numpy as np",
            "import matplotlib.pyplot as plt",
            "",
            "$0",
            "",
            "plt.show()"
        }
    }
}
