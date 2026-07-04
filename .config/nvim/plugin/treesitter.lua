--[[ Custom predicates and directives for Treesitter
 Mostly to avoid expensive operations within treesitter-scheme itself or as an
 escape hatch to do things treesitter wasn't made to do (e.g. selecting characters).

 All predicates and directives should have a jhk- prefix
 to avoid collisions with those added by e.g. nvim-treesitter. ]]

local M = {}
local directive = vim.treesitter.query.add_directive

--[[ Conceal Symbol Names in Typst {{{
 The goal here is not to make Vim a typst previewer, but rather to make
 equations easily parseable with the eye alone.
]]

-- Plain words (or functions) that should be replaced by a single symbol
local typst_symbol_names = {
    -- Greek alphabet {{{1
    Alpha             = "Α",
    alpha             = "α",
    Beta              = "Β",
    beta              = "β",
    ["beta.alt"]      = "ϐ",
    Gamma             = "Γ",
    gamma             = "γ",
    Delta             = "Δ",
    delta             = "δ",
    Epsilon           = "Ε",
    epsilon           = "ε",
    ["epsilon.alt"]   = "𝜖",
    ["epsilon.rev"]   = "϶",
    Zeta              = "Ζ",
    zeta              = "ζ",
    Eta               = "Η",
    eta               = "η",
    Theta             = "Θ",
    theta             = "θ",
    ["theta.alt"]     = "𝜗",
    Iota              = "Ι",
    iota              = "ι",
    Kappa             = "Κ",
    kappa             = "κ",
    ["kappa.alt"]     = "ϰ",
    Lambda            = "Λ",
    lambda            = "λ",
    Mu                = "Μ",
    mu                = "μ",
    Nu                = "Ν",
    nu                = "ν",
    Xi                = "ξ",
    xi                = "ξ",
    Omicron           = "Ο",
    omicron           = "ο",
    Pi                = "Π",
    pi                = "π",
    ["pi.alt"]        = "ϖ",
    Rho               = "Ρ",
    rho               = "ρ",
    ["rho.alt"]       = "ϱ",
    Sigma             = "Σ",
    sigma             = "σ",
    ["sigma.alt"]     = "ς",
    Tau               = "Τ",
    tau               = "τ",
    Upsilon           = "Υ",
    upsilon           = "υ",
    Phi               = "Φ",
    phi               = "φ",
    ["phi.alt"]       = "ϕ",
    Chi               = "Χ",
    chi               = "χ",
    Psi               = "Ψ",
    psi               = "ψ",
    Omega             = "Ω",
    ["Omega.inv"]     = "℧",
    omega             = "ω",
    -- }}}

    -- other letters
    CC                = "ℂ",
    NN                = "ℕ",
    QQ                = "ℚ",
    RR                = "ℝ",
    ZZ                = "ℤ",
    II                = "𝕀",
    Im                = "ℑ",
    Re                = "ℜ",

    -- attachable operations
    sum               = "∑",
    product           = "∏",
    ["product.co"]    = "∐",
    integral          = "∫",
    ["integral.cont"] = "∮",

    -- differential things
    grad              = "∇",
    nabla             = "∇",
    laplace           = "Δ",
    partial           = "𝜕",

    -- sets
    ["in"]            = "∈",
    subset            = "⊂",
    ["subset.eq"]     = "⊆",
    inter             = "∩",
    union             = "∪",

    -- other symbols
    ["circle.small"]  = "⚬",
    circle            = "○",
    degree            = "°",

    arrow             = "→",
    ["arrow.t"]       = "↑",
    ["arrow.l"]       = "←",
    ["arrow.r"]       = "→",
    ["arrow.b"]       = "↓",

    times             = "×",
    sqrt              = "√",
    slash             = "/",
    dagger            = "†",

    ["plus.minus"]    = "±",
    approx            = "≈",

    dot               = "⋅",
    dots              = "…",
    ["dots.down"]     = "⋱",
    ["dots.v"]        = "⋮",

    exists            = "∃",
    forall            = "∀",
    infinity          = "∞",
    hbar              = "ℏ"
}

-- Equivalent to the above, but for functions that "wrap" their argument
local typst_brace_names = {
    abs = { "|", "|" },
    -- not a standard typst function, but I often use physica
    iprod = { "⟨", "⟩" },
    -- ditto
    Set = { "{", "}" }
}

-- Allow modifying from outside
-- TODO?: Maybe a quick way to add a conceal temporarily via a user command
M.typst_symbol_names = typst_symbol_names
M.typst_brace_names = typst_symbol_names

directive("jhk-typst-set-symbol-conceal!", function(match, pattern, source, predicate, metadata)
    local id = predicate[2]
    local node = match[id][1]
    if not node then
        return
    end


    if not metadata[id] then
        metadata[id] = {}
    end
    local text = vim.treesitter.get_node_text(node, source)

    metadata[id].conceal = typst_symbol_names[text]
end, {})

directive("jhk-typst-set-bracket-conceal!", function(match, pattern, source, predicate, metadata)
    local open_id = predicate[2]
    local open_bracket = predicate[3]
    local close_id = predicate[4]
    local node = match[open_id][1]
    if not node then
        return
    end


    local text = vim.treesitter.get_node_text(node, source)
    local pair = typst_brace_names[text]
    if not pair then
        return
    end

    if not metadata[open_id] then
        metadata[open_id] = {}
    end
    if not metadata[close_id] then
        metadata[close_id] = {}
    end
    if not metadata[open_bracket] then
        metadata[open_bracket] = {}
    end

    metadata[open_id].conceal = ""
    metadata[open_bracket].conceal = pair[1]
    metadata[close_id].conceal = pair[2]
end, {})
-- }}}

-- Only select n initial characters of a node
directive("jhk-set-length!", function(match, pattern, source, predicate, metadata)
    local id = predicate[2]
    local node = match[id][1]
    if not node then
        return
    end

    if not metadata[id] then
        metadata[id] = {}
    end
    if not metadata[id].range then
        local srow, scol, erow, ecol = vim.treesitter.get_node_range(node)
        metadata[id].range = { srow, scol, erow, ecol }
    end
    metadata[id].range[4] = metadata[id].range[2] + tonumber(predicate[3])
end, {})

return M
