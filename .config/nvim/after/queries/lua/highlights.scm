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

; NOTE: maybe I want this at some point
; highlight require calls like module imports
; (function_call
;   name: (identifier) @keyword.import
;   arguments: (arguments
;     (string) @module)
;   (#eq? @keyword.import "require"))
