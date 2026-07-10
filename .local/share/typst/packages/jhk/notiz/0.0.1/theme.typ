#let style-state = state("jhk-theme")

#let current-theme() = style-state.get()
#let mix-theme(field, col, lvl) = {
  let theme = current-theme()
  color.mix((theme.at(field), lvl), (col, 100% - lvl))
}
#let theme-color(col) = () => current-theme().at(col)
#let static-color(col) = () => col
