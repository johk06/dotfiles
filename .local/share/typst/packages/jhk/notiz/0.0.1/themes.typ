#let custom-bg(bg) = (col, lvl) => color.mix((bg, lvl), (col, 100% - lvl))
#let make-theme(light, dark, colors) = {
  if not "alert" in colors {
    colors.alert = colors.red
  }
  if not "note" in colors {
    colors.note = colors.blue
  }
  (
    light: light + colors,
    dark: dark + colors,
  )
}

#let basic = make-theme(
  (bg: white, fg: black),
  (bg: black, fg: white),
  (
    red: red,
    orange: orange,
    yellow: yellow,
    green: green,
    teal: teal,
    blue: blue,
    purple: purple,
  ),
)

#let c = color.rgb
#let nord = make-theme(
  (bg: c("#eceff4"), fg: c("#2e3440")),
  (bg: c("#2e3440"), fg: c("#eceff4")),
  (
    red: c("#bf616a"),
    orange: c("#d08770"),
    yellow: c("#ebcb8b"),
    green: c("#a3be8c"),
    teal: c("#8fbcbb"),
    blue: c("#5e81ac"),
    purple: c("#9a8aac"),
  ),
)

#let grayscale = make-theme(
  (bg: white, fg: black),
  (bg: black, fg: white),
  (
    red: c("#555555"),
    orange: c("#777777"),
    yellow: c("#CCCCCC"),
    green: c("#666666"),
    teal: c("#888888"),
    blue: c("#444444"),
    purple: c("#4A4A4A"),
  ),
)

#let themes = (
  basic: basic,
  nord: nord,
  gray: grayscale,
)
