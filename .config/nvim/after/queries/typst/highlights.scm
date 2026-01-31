; extends

((field
  (ident)
  field: (ident)) @constant
  (#has-ancestor? @constant formula)
  (#jhk-typst-set-symbol-conceal! @constant))

(call
  item: (ident) @function.call
  (#has-ancestor? @function.call formula)
  (#jhk-typst-set-symbol-conceal! @function.call))

((ident) @constant
  (#has-ancestor? @constant formula)
  (#not-has-parent? @constant field)
  (#jhk-typst-set-symbol-conceal! @constant))
