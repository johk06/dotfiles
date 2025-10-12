; extends

(formula
  (ident) @constant.typst
  (#jhk-typst-set-symbol-conceal! @constant.typst))

(formula
  (field
    (ident)
    field: (ident)) @constant.typst
  (#jhk-typst-set-symbol-conceal! @constant.typst))

(formula
  (call
    item: (ident) @function.call.typst
    (#jhk-typst-set-symbol-conceal! @function.call.typst)))

(formula
  (attach
    (ident) @constant.typst
    (#jhk-typst-set-symbol-conceal! @constant.typst)))
