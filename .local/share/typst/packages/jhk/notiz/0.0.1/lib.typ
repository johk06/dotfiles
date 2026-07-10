#import "./theme.typ": (
  current-theme, mix-theme, static-color, style-state, theme-color,
)
#import "./themes.typ": themes
#import "./blocks.typ": (
  colorbox, corollary, define-script-reference, definition, formula,
  minor-theorem, theorem,
)

// Show text highlighted with a color
#let highlight(text, color: color) = box(
  fill: color,
  inset: .3em,
  radius: 4pt,
  text,
)

#let highlighter(color) = {
  text => context {
    highlight(text, color: mix-theme("bg", color(), 80%))
  }
}
#let alert = highlighter(theme-color("alert"))
#let note = highlighter(theme-color("note"))

#let titlepage(title) = context {
  let theme = current-theme()
  page(align(center, box[
    #text(2em)[
      Zusammenfassung für \ #title
    ]
    #show outline.entry.where(level: 1): strong
    #columns(2, outline(depth: 4, indent: 1em))
    #let rainbow = gradient.linear(
      ..(
        (
          theme.red,
          theme.orange,
          theme.yellow,
          theme.green,
          theme.teal,
          theme.blue,
          theme.purple,
        ).map(x => mix-theme("bg", x, 80%))
      ),
    )
    #v(0.5cm)
    #v(1fr)
    #highlight(
      text(2em, style: "italic", [Viel Glück & Erfolg beim Lernen!]),
      color: rainbow,
    )
    \ #v(0pt)
    #alert[Keine Garantie auf Vollständigkeit oder Korrektheit, aber handgetippt]
  ]))
}

#let template(title: [], theme: themes.basic.light, it) = {
  // Use the named theme colors
  style-state.update(old => theme)
  set page(fill: theme.bg)
  set text(theme.fg)

  set table(
    stroke: (x, y) => {
      (
        top: if y > 0 { 0.5pt + theme.fg },
        left: if x > 0 { 0.5pt + theme.fg },
      )
    },
  )

  // Show titles strong
  show table.cell.where(y: 0): strong

  // Don't split math equations
  show math.equation.where(block: false): box
  // Easier to read
  show math.equation.where(block: true): set align(left)

  show ref: emph

  titlepage(title)

  // Only after the titlepage
  set page(numbering: "1 / 1")
  set heading(numbering: "1.")

  it
}
