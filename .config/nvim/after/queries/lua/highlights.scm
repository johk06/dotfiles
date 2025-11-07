; extends

; HACK: fix overwritten : highlight in lsp
([
  ";"
  ":"
  "::"
  ","
  "."
] @punctuation.delimiter
  (#set! priority 200))
