; extends

; Type casts are not mere punctuation that may be ignored
; They're an operator
(cast_expression
  [
    "("
    ")"
  ] @operator)

; highlight #include <some_header.h> like a module import
(preproc_include
  path: (_) @module)

; highlight these generic-like type macros in a saner way
; NOTE: set the priority to override clangd's behavior
; FIXME: this errors out when included from the c++ queries,
; since that does not have the (macro_type_specifier) node
; (macro_type_specifier
;   name: (_) @constructor
;   type: (_) @type
;   (#set! priority 200))
