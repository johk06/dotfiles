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

; ; Highlight type(var) == "type" like a "real" type
; ; NOTE: all of lua's type are "builtin"
; (binary_expression
;   left: (function_call
;     name: (identifier) @_fn)
;   right: (string
;     [
;       "\""
;       "'"
;     ] @punctuation.delimiter
;     content: (string_content) @type.builtin
;     [
;       "\""
;       "'"
;     ] @punctuation.delimiter)
;   (#eq? @_fn "type"))
