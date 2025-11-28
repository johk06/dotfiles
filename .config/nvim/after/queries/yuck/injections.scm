; extends

; the majority of defvars with a string argument are json
(list
  (symbol) @_fn
  (symbol)
  (string
    (string_fragment) @injection.content)
  (#eq? @_fn "defvar")
  (#set! injection.language "json"))

(list
  (symbol) @_fn
  (symbol)
  (string
    (string_fragment) @injection.content)
  (#eq? @_fn "deflisten")
  (#set! injection.language "bash"))
