local theme = require("theme.colors")
local col = theme.colors
local pal = theme.palettes.default
local blend = theme.blend

local function add_with_prefix(to_append, prefix, table)
    for k, v in pairs(table) do
        -- expand * at the start to be a "relative" link
        if v.link and v.link:sub(1, 1) == "*" then
            v.link = prefix .. v.link:sub(2)
        end
        to_append[prefix .. k] = v
    end
end

-- Basics {{{
local colorscheme = {

    -- built in editor highlights
    Normal                      = { fg = pal.fg0, bg = pal.bg0 },
    NormalFloat                 = { fg = pal.fg0, bg = pal.bg0 },
    FloatBorder                 = { fg = pal.bg3 },
    WinSeparator                = { fg = pal.bg2 },
    LineNr                      = { fg = col.bright_gray },
    LineNrAbove                 = { fg = blend(col.teal, col.bright_gray, 0.3) },
    LineNrBelow                 = { fg = blend(col.pink, col.bright_gray, 0.3) },
    CursorLineNr                = { fg = pal.fg0 },
    Cursor                      = { reverse = true },
    MultiCursorCursor           = { bg = pal.bg3 },
    CursorLine                  = { bg = pal.bg1 },
    CursorColumn                = { bg = pal.bg1 },
    ColorColumn                 = { bg = pal.bg01, blend = 90 },
    Tabline                     = {},
    StatusLine                  = { bg = pal.bg01 },
    Folded                      = {},
    FoldNumber                  = { fg = col.magenta, italic = true },
    FoldColumn                  = { fg = pal.bg3 },
    SignColumn                  = { fg = pal.bg3 },
    EndOfBuffer                 = { fg = pal.bg1 },
    Visual                      = { bg = pal.bg1 },
    NonText                     = { fg = col.bright_gray },
    SpecialKey                  = { link = "NonText" },
    MatchParen                  = { bg = pal.bg1, fg = col.pink },

    -- related to search &c
    Search                      = { bg = pal.bg1 },
    CurSearch                   = { bg = pal.bg3 },
    IncSearch                   = { bg = col.yellow, fg = pal.inverted },
    Substitute                  = { bg = col.yellow, fg = pal.inverted },
    LeapLabel                   = { fg = pal.inverted, bg = col.yellow, nocombine = true },

    -- sort of an extension from search
    BlinkenFind1                = { bg = col.pink, fg = pal.inverted },
    BlinkenFind2                = { bg = col.purple, fg = pal.inverted },
    BlinkenFind3                = { bg = col.blue, fg = pal.inverted },
    BlinkenFind4                = { bg = col.light_blue, fg = pal.inverted },
    BlinkenFind5                = { bg = col.teal, fg = pal.inverted },
    BlinkenFind6                = { bg = col.green, fg = pal.inverted },
    BlinkenFind7                = { bg = col.yellow, fg = pal.inverted },
    BlinkenFind8                = { bg = col.orange, fg = pal.inverted },
    BlinkenFind9                = { bg = col.red, fg = pal.inverted },
    BlinkenFind1Secondary       = { sp = col.pink, underline = true },
    BlinkenFind2Secondary       = { sp = col.purple, underline = true },
    BlinkenFind3Secondary       = { sp = col.blue, underline = true },
    BlinkenFind4Secondary       = { sp = col.light_blue, underline = true },
    BlinkenFind5Secondary       = { sp = col.teal, underline = true },
    BlinkenFind6Secondary       = { sp = col.green, underline = true },
    BlinkenFind7Secondary       = { sp = col.yellow, underline = true },
    BlinkenFind8Secondary       = { sp = col.orange, underline = true },
    BlinkenFind9Secondary       = { sp = col.red, underline = true },

    -- spelling
    SpellBad                    = { sp = col.red, undercurl = true },
    SpellRare                   = { sp = col.magenta, undercurl = true },
    SpellLocal                  = { sp = col.pink, undercurl = true },
    SpellCap                    = { sp = col.yellow, undercurl = true },

    -- diffs
    Added                       = { fg = col.green },
    Deleted                     = { fg = col.red },
    Removed                     = { link = "Deleted" },
    Changed                     = { fg = col.yellow },
    DiffChange                  = { bg = pal.bg1 },
    DiffAdd                     = { bg = pal.bg1, fg = col.green, italic = true },
    DiffText                    = { bg = pal.bg1, fg = col.yellow, italic = true },
    DiffDelete                  = { bg = blend(col.red, pal.bg3, 0.3) },
    diffFile                    = { link = "Directory" },

    -- messages
    Question                    = { fg = col.fg0 },
    Warnings                    = { fg = col.orange },
    ErrorMsg                    = { fg = col.red },
    MoreMSg                     = { fg = col.bright_gray },
    ModeMSg                     = { fg = col.bright_gray },

    -- popup menu
    Pmenu                       = { bg = pal.bg1, fg = pal.fg0 },
    PmenuSel                    = { bg = col.teal, fg = pal.inverted },
    PmenuKind                   = { fg = col.magenta },
    PmenuKindSel                = { fg = pal.inverted },
    PmenuExtra                  = { fg = pal.bg3 },
    PmenuExtraSel               = { fg = pal.bg3 },
    PmenuSbar                   = { fg = pal.fg2 },
    PmenuThumb                  = { fg = pal.fg0 },

    -- quick fix list
    qfFileName                  = { fg = col.light_blue },
    qfLineNr                    = { fg = col.magenta },
    qfSeparator                 = { link = "@punctuation.delimiter" },
    QuickFixLine                = { bg = pal.bg1 },
    QuickFixLineNr              = { fg = col.purple },
    QuickFixFilename            = { link = "Identifier" },

    -- built in syntax
    Boolean                     = { link = "@boolean" },
    Character                   = { link = "@character" },
    CodeBlock                   = { bg = pal.bg1 },
    Comment                     = { link = "@comment" },
    Conceal                     = { bg = pal.bg0 },
    Conditional                 = { link = "@keyword.conditional" },
    Constant                    = { link = "@constant" },
    Dash                        = { fg = col.blue, bold = true },
    Debug                       = { fg = col.red },
    Define                      = { link = "@keyword" },
    Delimiter                   = { link = "@punctuation.delimiter" },
    Directory                   = { fg = col.teal },
    Error                       = { fg = col.red, bold = true, underline = true },
    Exception                   = { fg = col.light_blue },
    Float                       = { link = "@float" },
    Function                    = { link = "@keyword.function" },
    htmlH1                      = { link = "@markup.heading.1" },
    htmlH2                      = { link = "@markup.heading.2" },
    htmlH3                      = { link = "@markup.heading.3" },
    htmlH4                      = { link = "@markup.heading.4" },
    htmlH5                      = { link = "@markup.heading.5" },
    htmlLink                    = { fg = col.blue, italic = true, underline = true },
    Identifier                  = { fg = col.light_blue },
    Ignore                      = { fg = pal.bg1 },
    Include                     = { link = "@keyword.import" },
    Keyword                     = { link = "@keyword" },
    Label                       = { link = "@symbol" },
    Macro                       = { link = "@macro" },
    markdownH1Delimiter         = { fg = col.light_cyan },
    markdownH1                  = { link = "@markup.heading.1" },
    markdownH2Delimiter         = { fg = col.red },
    markdownH2                  = { link = "@markup.heading.2" },
    markdownH3Delimiter         = { fg = col.green },
    markdownH3                  = { link = "@markup.heading.3" },
    Number                      = { link = "@number" },
    Operator                    = { link = "@operator" },
    PreCondit                   = { fg = col.yellow },
    PreProc                     = { fg = col.light_blue },
    Quote                       = { fg = pal.bg2 },
    Repeat                      = { link = "@keyword.repeat" },
    SpecialChar                 = { fg = col.yellow },
    SpecialComment              = { link = "@comment.note" },
    Special                     = { fg = pal.fg2 },
    Statement                   = { fg = col.light_blue },
    StorageClass                = { fg = col.light_blue },
    String                      = { link = "@string" },
    Struct                      = { link = "@type" },
    Structure                   = { link = "@type" },
    Tag                         = { fg = col.fg2 },
    Title                       = { link = "@markup.heading" },
    Todo                        = { link = "@comment.todo" },
    Typedef                     = { fg = col.light_blue },
    Type                        = { link = "@type" },
    Underlined                  = { fg = col.blue, underline = true },

    IndentBlanklineIndent       = { fg = pal.bg1 },
    IndentBlanklineScope        = { fg = col.bright_gray },

    TreesitterContext           = { bg = pal.bg01 },
    TreesitterContextLineNumber = { fg = col.teal },

    UndotreeTimeStamp           = { fg = col.light_blue },
    UndotreeCurrent             = { fg = col.teal },
    UndotreeNext                = { fg = col.yellow },
    UndotreeHead                = { fg = col.blue },
    UndotreeBranch              = { fg = col.magenta },
    UndotreeSavedSmall          = { fg = col.green },
    UndotreeSavedBig            = { fg = col.green, bg = pal.bg3 },

    Yanked                      = { bg = pal.bg1 },

    GrappleName                 = { fg = pal.fg0, italic = true },
    GrappleBold                 = { link = "Identifier" },
    GrappleCurrent              = { fg = col.teal },

    -- don't show those in italic
    helpExample                 = { link = "Normal" },

    manBold                     = { bg = pal.bg0 },
    manReference                = { link = "@markup.link" },
}
-- }}}

-- Ufo - Folds {{{
add_with_prefix(colorscheme, "Ufo", {
    FoldedFg     = {},
    FoldedBg     = {},
    PreviewThumb = {},

    Suffix       = { fg = col.bright_gray, },
    FoldTitle    = { fg = col.teal, bg = pal.bg01 },
})
-- }}}

-- Treesitter {{{
-- this is the majority of the actual syntax highlighting
add_with_prefix(colorscheme, "@", {
    number                           = { fg = col.magenta },
    float                            = { fg = col.magenta },
    macro                            = {},
    character                        = { fg = col.green },
    boolean                          = { fg = col.teal },
    property                         = { fg = col.blue },
    constructor                      = { link = "*function" },
    operator                         = { fg = col.teal },
    symbol                           = { fg = col.magenta },
    module                           = { fg = col.yellow },

    ["comment"]                      = { fg = col.bright_gray, italic = true },
    ["comment.todo"]                 = { fg = col.yellow, italic = true, underline = true },
    ["comment.error"]                = { fg = col.red, italic = true, underline = true },
    ["comment.warning"]              = { fg = col.orange, italic = true, underline = true },
    ["comment.note"]                 = { fg = col.light_blue, italic = true, underline = true },
    -- user names like `INFO(jo): Some message`
    ["constant.comment"]             = { fg = col.purple, italic = true },

    ["string"]                       = { fg = col.green },
    ["string.documentation"]         = { link = "*comment" },
    ["string.special.path"]          = { fg = col.teal },
    ["string.regex"]                 = { fg = col.orange },
    ["string.escape"]                = { fg = col.yellow },
    -- delimiter based formats: highlight strings like words
    ["string.csv"]                   = { link = "Normal" },
    ["string.psv"]                   = { link = "Normal" },
    ["string.tsv"]                   = { link = "Normal" },

    ["variable"]                     = { fg = pal.fg2 },
    ["variable.member"]              = { link = "*property" },
    ["variable.builtin"]             = { fg = pal.fg0, italic = true },
    ["variable.parameter.builtin"]   = { fg = col.light_blue, italic = true },

    ["constant"]                     = { fg = col.fg3 },
    ["constant.builtin"]             = { fg = col.fg3 },

    ["type"]                         = { fg = col.magenta },
    ["type.builtin"]                 = { fg = col.purple },

    ["function"]                     = { fg = col.light_blue },
    ["function.builtin"]             = { fg = col.light_cyan },

    ["punctuation.bracket"]          = { fg = col.bright_gray },
    ["punctuation.special"]          = { fg = col.light_cyan },
    ["punctuation.special.markdown"] = { fg = col.light_gray },
    ["punctuation.delimiter"]        = { fg = col.bright_gray },

    ["attribute"]                    = { fg = col.yellow },
    ["attribute.builtin"]            = { fg = col.yellow },

    ["keyword"]                      = { fg = col.light_blue },
    ["keyword.return"]               = { fg = col.light_blue, italic = true },
    ["keyword.import"]               = { fg = col.light_blue },
    ["keyword.repeat"]               = { fg = col.light_blue, italic = true },
    ["keyword.conditional"]          = { fg = col.light_blue, italic = true },
    ["keyword.function"]             = { link = "*function" },
    ["keyword.operator"]             = { link = "*operator" },

    ["text"]                         = { fg = pal.fg2 },
    ["text.reference"]               = { fg = col.magenta },
    ["text.emphasis"]                = { fg = pal.fg0, italic = true },
    ["text.underline"]               = { fg = pal.fg0, underline = true },
    ["text.literal"]                 = { fg = pal.fg2 },
    ["text.uri"]                     = { fg = col.blue, italic = true },
    ["text.strike"]                  = { fg = pal.fg0, strikethrough = true },
    ["text.title"]                   = { fg = col.blue },
    ["text.strong"]                  = { fg = pal.fg0, bold = true },

    ["diff.plus"]                    = { fg = col.green },
    ["diff.minus"]                   = { fg = col.red },
    ["diff.delta"]                   = { fg = col.yellow },

    ["tag"]                          = { link = "*keyword" },
    ["tag.attribute"]                = { fg = pal.fg0 },
    ["tag.builtin"]                  = { fg = col.light_blue },
    ["tag.delimiter"]                = { fg = col.bright_gray },

    -- show headings with underlines
    ["markup.heading"]               = { fg = col.teal, bold = true },
    ["markup.heading.1"]             = { fg = col.yellow, bold = true, underline = true },
    ["markup.heading.2"]             = { fg = col.green, bold = true, underline = true },
    ["markup.heading.3"]             = { fg = col.teal, bold = true, underline = true },
    ["markup.heading.4"]             = { fg = col.light_cyan, underline = true },
    ["markup.heading.5"]             = { fg = col.light_blue, underline = true },
    ["markup.heading.6"]             = { fg = col.blue, underline = true },

    -- those already have a prominent line above them
    ["markup.heading.1.vimdoc"]      = { fg = col.yellow, bold = true },
    ["markup.heading.2.vimdoc"]      = { fg = col.green, bold = true },
    ["markup.heading.3.vimdoc"]      = { fg = col.teal, bold = true },
    ["markup.heading.4.vimdoc"]      = { fg = col.light_cyan, bold = true },

    -- I don't want the whole commit message to be colored
    ["markup.heading.gitcommit"]     = {},

    ["markup.math"]                  = { italic = true },
    ["markup.raw.markdown_inline"]   = { bg = pal.bg01 },
    ["markup.link"]                  = { fg = col.blue },
    ["markup.link.url"]              = { fg = col.blue, underline = true, nocombine = true },
    ["markup.link.label"]            = { fg = col.light_blue },
    ["markup.quote"]                 = { italic = true },
    ["markup.list"]                  = { fg = col.light_blue },
    ["markup.list.checked"]          = { fg = col.bright_gray },
    ["markup.list.unchecked"]        = { fg = col.yellow, bg = pal.bg1 },

    -- NOTE: those are only defined by my custom printf queries
    ["character.printf"]             = {},
    ["number.printf"]                = { fg = col.magenta, sp = col.magenta, underline = true },
    ["constant.printf"]              = { fg = col.yellow, sp = col.yellow, underline = true },
    ["float.printf"]                 = { fg = col.magenta, sp = col.magenta, underline = true },
    ["symbol.printf"]                = { fg = col.light_blue, sp = col.light_blue, underline = true },
    ["string.printf"]                = { fg = col.green, sp = col.green, underline = true },
})
-- }}}

-- LSP semantic highlights {{{
add_with_prefix(colorscheme, "@lsp.", {
    ["type.macro"]                    = { link = "@macro" },
    ["type.enum"]                     = { fg = col.yellow, },
    ["type.escape"]                   = { link = "@string.escape" },
    ["type.delim"]                    = { link = "@punctuation.delimiter" },

    ["mod.deprecated"]                = { fg = col.bright_gray, italic = true, strikethrough = true },

    -- ["typemod.function.defaultLibrary"] = { link = "@function.builtin" },
    -- override what the LSP does so --HACK etc work
    ["type.comment"]                  = {},
    ["typemod.keyword.documentation"] = { fg = col.light_blue },
})
-- }}}

-- Bufferline and Statusline {{{
-- groups beginning with A* are for active sections
-- I* is inactive
add_with_prefix(colorscheme, "Sl", {
    -- buffer types
    AReg        = { bg = pal.bg1, fg = col.light_blue },
    IReg        = { fg = col.light_blue },
    ASpecial    = { bg = pal.bg1, fg = col.magenta },
    ISpecial    = { fg = col.magenta },
    AHelp       = { bg = pal.bg1, fg = col.yellow },
    IHelp       = { fg = col.yellow },
    ATerm       = { bg = pal.bg1, fg = col.orange },
    ITerm       = { fg = col.orange },
    IDir        = { fg = col.teal },
    ADir        = { bg = pal.bg1, fg = col.teal },
    IList       = { fg = col.magenta },
    AList       = { bg = pal.bg1, fg = col.magenta },
    IGit        = { fg = col.green },
    AGit        = { bg = pal.bg1, fg = col.green },

    ATab        = { bg = pal.bg1, fg = col.pink },
    ITab        = { fg = col.pink },

    -- indicator fields
    AChanged    = { bg = pal.bg1, fg = col.yellow },
    IChanged    = { fg = col.yellow },
    AReadonly   = { bg = pal.bg1, fg = col.bright_gray },
    IReadonly   = { fg = col.bright_gray },
    AText       = { bg = pal.bg1, fg = pal.fg0 },
    IText       = { fg = pal.fg0 },
    AHidden     = { bg = pal.bg1, fg = col.bright_gray },
    IHidden     = { fg = col.bright_gray },
    AAltText    = { bg = pal.bg1, fg = pal.fg0 },
    IAltText    = { fg = pal.fg0, underline = true, sp = col.bright_gray },
    AAltHidden  = { bg = pal.bg1, fg = col.bright_gray, underline = true },
    IAltHidden  = { fg = col.bright_gray, underline = true },
    AGrapple    = { bg = pal.bg1, fg = col.magenta },
    IGrapple    = { fg = col.magenta },

    -- separators
    Delim       = { fg = col.bright_gray },
    ASL         = { fg = pal.bg1, bg = pal.bg0 },
    ASR         = { fg = pal.bg1, bg = pal.bg0 },
    ISL         = { fg = pal.bg01, bg = pal.bg0 },
    ISR         = { fg = pal.bg01, bg = pal.bg0 },

    -- in the statusline: counts of various things
    Words       = { fg = col.yellow },
    Chars       = { fg = col.green },
    Lines       = { fg = col.teal },
    Bytes       = { fg = col.magenta },

    -- left section of the statusline
    Typed       = { fg = pal.fg0 },
    Macro       = { fg = col.yellow },
    OnSearch    = { bg = pal.bg2, fg = col.yellow },

    -- and the modes
    ModeNormal  = { fg = col.teal },
    ModeInsert  = { fg = col.white },
    ModeCommand = { fg = col.green },
    ModeVisual  = { fg = col.light_blue },
    ModeReplace = { fg = col.red },
})
-- }}}

-- Startscreen {{{
add_with_prefix(colorscheme, "Dashboard", {
    -- for the big neovim logo
    Title1    = { fg = col.red },
    Title2    = { fg = col.orange },
    Title3    = { fg = col.yellow },
    Title4    = { fg = col.green },
    Title5    = { fg = col.teal },
    Title6    = { fg = col.light_blue },

    Property  = { fg = col.blue, italic = true },
    Message   = { italic = true },

    -- entries
    FindFiles = { fg = col.blue },
    EditFiles = { fg = col.light_blue },
    Agenda    = { fg = col.teal },
    Capture   = { fg = col.green },
    Lazy      = { fg = col.yellow },
    Mason     = { fg = col.orange },
    Quit      = { fg = col.red },

    Actions   = { fg = col.purple, bg = pal.bg01, italic = true },
    Projects  = { fg = col.light_blue, bg = pal.bg01, italic = true },
    Recents   = { fg = col.green, bg = pal.bg01, italic = true },
})
-- }}}

-- Files {{{
-- this means general metadata attached to files
add_with_prefix(colorscheme, "File", {
    -- use brighter colors for newer files,
    -- they're more relevant most of the time
    TimeLastMinute    = { fg = col.yellow },
    TimeLastHour      = { fg = col.green },
    TimeLastDay       = { fg = col.teal },
    TimeLastFewDays   = { fg = col.light_blue },
    TimeLastWeek      = { fg = col.blue },
    TimeLastFortnight = { fg = blend(col.blue, col.purple, 0.5) },
    TimeLastMonth     = { fg = col.purple },
    TimeLastYear      = { fg = blend(col.purple, pal.bg3, 0.8) },
    TimeSuperOld      = { fg = col.bright_gray },

    SizeNone          = { fg = pal.bg3 },
    SizeTiny          = { fg = col.bright_gray },
    SizeSmall         = { fg = col.fg0 },
    SizeMedium        = { fg = col.pink },
    SizeLarge         = { fg = col.yellow },
    SizeHuge          = { fg = col.orange },
    SizeTooBig        = { fg = col.red },

    TypeExecutable    = { fg = col.green, bold = true },
    TypeCode          = { fg = col.light_blue },
    TypeHeader        = { fg = col.yellow },
    TypeMarkup        = { fg = col.magenta },
    TypeText          = { fg = pal.fg2 },
    TypeBin           = { fg = col.orange },
    TypeArchive       = { fg = col.orange },
    TypeConfig        = { fg = col.purple },
    TypeMeta          = { fg = col.light_blue, italic = true },
    TypeBuild         = { fg = col.green },
    TypeIgnore        = { fg = col.bright_gray },
    TypeReadme        = { fg = col.magenta },
    TypeStyle         = { link = "*TypeConfig" },
    TypeGit           = { fg = col.green },

    TypeSocket        = { fg = col.magenta },
    TypeBlockDev      = { fg = col.yellow, bg = pal.bg1 },
    TypeCharDev       = { fg = col.green, bg = pal.bg1 },
    TypeNormal        = { link = "Normal" },
    TypeHidden        = { fg = pal.fg1 },
})
-- }}}

-- Oil {{{
add_with_prefix(colorscheme, "Oil", {
    Link             = { fg = col.blue, bold = true },
    OrphanLink       = { fg = col.blue },
    Dir              = { fg = col.teal, bold = true },
    Hidden           = { link = "FileHidden" },
    DirHidden        = { link = "*Dir" },
    LinkTarget       = { fg = col.blue, italic = true },
    OrphanLinkTarget = { fg = col.red, italic = true },

    -- columns
    Read             = { fg = col.yellow },
    Write            = { fg = col.orange },
    Exec             = { fg = col.green },
    Setuid           = { fg = col.red, bold = true },
    Sticky           = { fg = col.blue, bold = true },
    NoPerm           = { fg = pal.bg3 },
    User             = { fg = col.purple },
    Group            = { fg = col.blue },

    Delete           = { fg = col.red, bold = true },
    Create           = { fg = col.green },
    Move             = { fg = col.orange },
    Copy             = { fg = col.yellow },
    Change           = { fg = col.magenta },
})


add_with_prefix(colorscheme, "OilGit", {
    Ignored        = { fg = pal.bg3 },
    Untracked      = { fg = pal.fg2 },
    Added          = { fg = col.green },
    Copied         = { fg = col.green },
    Deleted        = { fg = col.red },
    Modified       = { fg = col.yellow },
    Renamed        = { fg = col.magenta },
    TypeChanged    = { fg = col.orange },
    Unmerged       = { fg = pal.fg0 },
})

-- }}}

-- Blink {{{
add_with_prefix(colorscheme, "BlinkCmp", {
    Menu                = { link = "Normal" },
    MenuBorder          = { fg = pal.bg3 },
    MenuSelection       = { bg = pal.bg1 },
    Label               = { link = "Normal" },
    DocBorder           = { link = "*MenuBorder" },
    LabelMatch          = { sp = col.bright_gray, underline = true, fg = col.pink },
    Index               = { fg = col.teal },

    SignatureHelpBorder = { link = "*MenuBorder" },

    Kind                = { fg = col.yellow },
    KindArray           = { fg = col.light_blue },
    KindBoolean         = { link = "@boolean" },
    KindClass           = { fg = col.magenta },
    KindConstant        = { fg = col.yellow },
    KindConstructor     = { fg = col.magenta },
    KindEnumMember      = { fg = pal.fg0 },
    KindField           = { fg = pal.fg0 },
    KindFile            = { fg = col.yellow },
    KindFolder          = { fg = col.light_blue },
    KindFunction        = { fg = col.teal },
    KindInterface       = { fg = col.magenta },
    KindKeyword         = { fg = pal.fg0 },
    KindLatex           = { fg = col.green },
    KindProperty        = { fg = pal.fg0 },
    KindNamespace       = { fg = col.green },
    KindMethod          = { fg = col.teal },
    KindModule          = { fg = col.green },
    KindNeorg           = { fg = col.light_blue },
    KindNumber          = { link = "@number" },
    KindObject          = { fg = col.light_blue },
    KindPackage         = { fg = col.green },
    KindSnippet         = { fg = col.pink },
    KindString          = { link = "@string" },
    KindStruct          = { link = "*ItemKindClass" },
    KindText            = { fg = pal.bg3 },
    KindVariable        = { fg = pal.fg0 },
})
-- }}}

-- LSP & Diagnostics {{{
add_with_prefix(colorscheme, "Lsp", {
    InlayHint       = { fg = col.bright_gray, italic = true },
    InfoBorder      = { fg = pal.bg3 },
    StaticMethod    = { fg = col.magenta },
    ReferenceTarget = {},
    ReferenceText   = { link = "Substitute" },
    ReferenceRead   = { link = "Substitute" },
    ReferenceWrite  = { link = "Substitute" },
})

add_with_prefix(colorscheme, "Diagnostic", {
    Error            = { fg = col.red },
    SignError        = { link = "*Error" },
    UnderlineError   = { undercurl = true, sp = col.red },
    VirtualTextError = { fg = col.red, italic = true },
    FloatingError    = { link = "*Error" },

    Warn             = { fg = col.orange },
    SignWarn         = { link = "*Warn" },
    UnderlineWarn    = { undercurl = true, sp = col.orange },
    VirtualTextWarn  = { fg = col.orange, italic = true },
    FloatingWarn     = { link = "*Warn" },

    Info             = { fg = col.blue },
    SignInfo         = { link = "*Info" },
    UnderlineInfo    = { undercurl = true, sp = col.blue },
    VirtualTextInfo  = { fg = col.blue, italic = true },
    FloatingInfo     = { link = "*Info" },

    Hint             = { fg = col.light_blue },
    SignHint         = { link = "*Hint" },
    UnderlineHint    = { undercurl = true, sp = col.light_blue },
    VirtualTextHint  = { fg = col.light_blue, italic = true },
    FloatingHint     = { link = "*Hint" },

    Ok               = { fg = col.green },
    SignOk           = { link = "*Ok" },
    UnderlineOk      = { undercurl = true, sp = col.green },
    VirtualTextOk    = { fg = col.green, italic = true },
    FloatingOk       = { link = "*Ok" },

    Deprecated       = { link = "@lsp.mod.deprecated" },
    Unnecessary      = { undercurl = true, sp = col.bright_gray }
})
-- }}}

-- Mason {{{
add_with_prefix(colorscheme, "Mason", {
    Header                      = { fg = pal.bg0, bg = col.teal },
    HeaderSecondary             = { fg = pal.bg0, bg = col.teal },
    Highlight                   = { fg = col.yellow },
    HighlightBlock              = { fg = pal.bg0, bg = col.teal },
    HighlightBlockBold          = { link = "*HighlightBlock" },
    HighlightSecondary          = { link = "*Highlight" },
    HighlightSecondaryBlock     = { link = "*HighlightBlock" },
    HighlightSecondaryBlockBold = { link = "*HighlightBlockBold" },
    Muted                       = { link = "NonText" },
    MutedBlock                  = { bg = pal.bg1 },
    MutedBlockBold              = { link = "*MutedBlock" },
    Backdrop                    = { link = "Normal" },
})
-- }}}

-- Overrides for vim syntax {{{
add_with_prefix(colorscheme, "zsh", {
    Deref       = { link = "@variable" },
    VariableDef = { link = "@variable" },
    Function    = { link = "@function" },
    KSHFunction = { link = "@function" },
    Operator    = { link = "@operator" },
})
-- }}}

-- git: gitsigns and fugitive {{{
add_with_prefix(colorscheme, "GitSigns", {
    Add                = { fg = pal.bg3 },
    AddNr              = { fg = pal.bg3 },
    AddLn              = { fg = pal.bg3 },
    Change             = { fg = col.yellow },
    ChangeNr           = { fg = pal.bg3 },
    ChangeLn           = { fg = pal.bg3 },
    ChangeDelete       = { fg = col.orange },
    Delete             = { fg = col.red },
    DeleteNr           = { fg = pal.bg3 },
    DeleteLn           = { fg = pal.bg3 },
    CurrentLineBlame   = { bg = pal.bg1, fg = pal.fg0, nocombine = true },
    AddInline          = { bg = pal.bg1, fg = col.green, italic = true },
    DeleteInline       = { bg = pal.bg1, fg = col.red, italic = true },
    ChangeInline       = { bg = pal.bg1, fg = col.yellow, italic = true },

    StagedAdd          = { fg = col.green, bold = true },
    StagedDelete       = { fg = col.red, bold = true },
    StagedChange       = { fg = col.yellow, bold = true },
    StagedChangeDelete = { fg = col.orange, bold = true },
})

add_with_prefix(colorscheme, "fugitive", {
    UntrackedHeading  = { fg = col.purple, italic = true },
    UntrackedModifier = { fg = col.purple },

    UnstagedHeading   = { fg = col.yellow, italic = true },
    UnstagedModifier  = { fg = col.yellow },

    StagedHeading     = { fg = col.green, italic = true },
    StagedModifier    = { fg = col.green },

    Header            = { link = "@property" },
    SymbolicRef       = { fg = col.green },
})

add_with_prefix(colorscheme, "git", {
    Keyword         = { link = "@property" },
    IdentityHeader  = { link = "@property" },
    DateHeader      = { link = "@property" },
    IdentityKeyword = { link = "@property" },
    File            = { link = "diffFile" },
})
-- }}}

-- Telescope {{{
add_with_prefix(colorscheme, "Telescope", {
    PromptBorder          = { fg = pal.bg3 },
    PromptTitle           = { fg = col.teal },
    ResultsBorder         = { fg = pal.bg3 },
    PreviewBorder         = { fg = pal.bg3 },
    ResultsSpecialComment = { fg = col.pink },
    Selection             = { bg = pal.bg1 },
    PromptPrefix          = { fg = col.teal },
    SelectionCaret        = { bg = pal.bg1 },
    MultiSelection        = { bg = pal.bg01 },
    MultiIcon             = { bg = col.yellow, fg = pal.inverted },
    Matching              = { fg = col.yellow, underline = true },

    PreviewExecute        = { link = "OilExec" },
    PreviewRead           = { link = "OilRead" },
    PreviewWrite          = { link = "OilWrite" },
    PreviewSticky         = { link = "OilSticky" },
    PreviewLink           = { link = "OilLink" },
    PreviewHyphen         = { link = "OilNoPerm" },
    PreviewDate           = { fg = col.light_cyan },

    ResultsDiffAdd        = { fg = col.green },
    ResultsDiffChange     = { fg = col.yellow },
    ResultsDiffDelete     = { fg = col.red },
    ResultsDiffUntracked  = { fg = col.bright_gray },
    ResultsLineNr         = { fg = col.magenta },
})
-- }}}

-- Grug-Far {{{
add_with_prefix(colorscheme, "GrugFar", {
    InputLabel         = { fg = col.teal, italic = true },
    ResultsPath        = { link = "Directory" },
    ResultsMatch       = { bg = pal.bg01, fg = col.yellow, italic = true },
    ResultsNumberLabel = { link = "Label" },
})
-- }}}

-- Orgmode {{{
add_with_prefix(colorscheme, "@org.", {
    ["headline.level1"]       = { fg = col.yellow, bold = true },
    ["headline.level2"]       = { fg = col.green, bold = true },
    ["headline.level3"]       = { fg = col.teal, bold = true },
    ["headline.level4"]       = { fg = col.light_cyan, bold = true },
    ["headline.level5"]       = { fg = col.light_blue, bold = true },
    ["headline.level6"]       = { fg = col.pink, bold = true },
    ["headline.level7"]       = { fg = pal.fg0, bold = true },
    ["headline.level8"]       = { fg = pal.fg0 },

    ["table.delimiter"]       = { link = "@punctuation.delimiter" },

    ["keyword.todo"]          = { fg = pal.fg0, italic = true, nocombine = true },
    ["keyword.done"]          = { fg = col.bright_gray, nocombine = true },
    ["keyword.face.NEXT"]     = { fg = col.green, italic = true, nocombine = true },
    ["keyword.face.WAITING"]  = { fg = col.teal, italic = true, nocombine = true },
    ["keyword.face.CURRENT"]  = { fg = col.magenta, italic = true, nocombine = true },
    ["keyword.face.NOPE"]     = { fg = col.bright_gray, strikethrough = true, nocombine = true },
    ["priority.highest"]      = { fg = col.orange, nocombine = true },
    ["priority.default"]      = { fg = col.green, nocombine = true },
    ["priority.lowest"]       = { fg = col.bright_gray, nocombine = true },
    ["plan"]                  = { fg = col.light_blue },
    ["timestamp.active"]      = { fg = col.magenta },
    ["tag"]                   = { fg = col.purple, nocombine = true },
    ["verbatim"]              = { bg = pal.bg01 },
    ["code"]                  = { bg = pal.bg01 },

    ["agenda.header"]         = { link = "*headline.level1" },
    ["agenda.day"]            = { fg = pal.fg0 },
    ["agenda.today"]          = { fg = pal.fg0, bg = pal.bg01 },
    ["agenda.scheduled"]      = { fg = pal.fg0, italic = true },
    ["agenda.scheduled_past"] = { fg = pal.fg0, italic = true },
    ["agenda.deadline"]       = { fg = col.orange, italic = true },
    ["agenda.weekend"]        = { fg = col.bright_gray },

    ["hyperlink"]             = { link = "@punctuation.delimiter" },
    ["bullet"]                = { fg = col.bright_gray },
    ["checkbox"]              = { fg = col.bright_gray },
    ["checkbox.checked"]      = { fg = col.bright_gray },
    ["checkbox.halfchecked"]  = { fg = col.magenta },

    properties                = { fg = col.bright_gray },
})

add_with_prefix(colorscheme, "Org", {
    CalendarSelected = { bg = pal.bg1 },
    CalendarToday    = { fg = col.teal },
})
-- }}}

return colorscheme
