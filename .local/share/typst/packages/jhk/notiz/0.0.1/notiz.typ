#let notiz(lecture, doc) = {
  import "@preview/physica:0.9.6"
  set text(font: "Liberation Serif")
  show math.equation: set text(font: "Libertinus Math")

  outline(
    title: lecture,
    depth: 3,
  )
  pagebreak()
  counter(page).update(1)
  set heading(
    numbering: "1.1.a.i"
  )

  doc
}
