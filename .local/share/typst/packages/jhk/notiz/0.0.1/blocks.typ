#import "./theme.typ": current-theme, mix-theme, theme-color
#import "@preview/showybox:2.0.4"
#let colorbox(color, title, body) = context {
  let theme = current-theme()
  let col = color()
  showybox.showybox(
    title-style: (
      weight: 900,
      color: mix-theme("fg", col, 40%),
      sep-thickness: 0pt,
    ),
    body-style: (
      color: theme.fg,
    ),
    frame: (
      title-color: mix-theme("bg", col, 80%),
      border-color: mix-theme("fg", col, 40%),
      thickness: (left: 1pt),
      body-color: mix-theme("bg", col, 90%),
      radius: 0pt,
    ),
    title: title,
    body,
  )
}

#let _ref-label(kind, name) = label(
  lower(kind) + ":" + name.replace(regex("\s"), "_"),
)
#let _ref-target-label(name, nr) = {
  if nr != none {
    [#nr -- ]
  }
  [#(sym.quote.low)#(name)#(sym.quote.high)]
}

#let define-script-reference(color, kind, outline: false, abbrev: none) = {
  let shortkind = if abbrev != none { abbrev } else { kind }
  return (name, body, pg: none, nr: none, ref: none, outline: outline) => {
    let cleanname = if not name.has("text") {
      assert(
        ref != none,
        message: "Either an explicit `ref` or name as a simple content need to be given",
      )
      ref
    } else {
      name.text
    }
    [ #figure(
        kind: kind.text,
        numbering: it => _ref-target-label(name, nr),
        supplement: kind,
        context {
          let prev = query(selector(heading).before(here()))
            .filter(el => el.numbering != none)
            .map(it => it.level)
            .last()
          set enum(numbering: numbering)
          set heading(level: 4, numbering: none, outlined: false)
          colorbox(
            color,
            {
              show heading: none
              // Only for the outline :)
              heading(
                numbering: none,
                outlined: outline,
                level: prev + 1,
              )[#shortkind: #name]
              name
              h(1fr)
              if nr != none {
                [#kind #nr]
              }
              if pg != none {
                [ [S. #pg]]
              }
            },
            body,
          )
        },
      )
      #_ref-label(shortkind.text, cleanname)
    ]
  }
}

#let theorem = define-script-reference(
  theme-color("purple"),
  [Satz],
  outline: true,
)
#let minor-theorem = define-script-reference(
  theme-color("blue"),
  [Satz],
  outline: false,
)
#let definition = define-script-reference(
  theme-color("green"),
  [Definition],
  outline: true,
  abbrev: [Def],
)
#let formula = define-script-reference(
  theme-color("red"),
  [Formel],
  outline: true,
)
#let corollary = define-script-reference(
  theme-color("teal"),
  [Korollar],
)
#let example = define-script-reference(
  theme-color("teal"),
  [Beispiel],
  abbrev: [Bsp.]
)
