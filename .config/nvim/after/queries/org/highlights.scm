; extends

(block
  parameter: (expr) @property
  (#lua-match? @property "^:"))

(block
  (expr) @_name
  .
  (expr) @label
  (#eq? @_name "src"))

(directive
  name: (expr) @_name
  value: (value) @markup.heading @spell
  (#eq? @_name "title"))

(directive
  name: (expr) @_name
  value: (value) @constant
  (#eq? @_name "author"))

(expr
  "$" @bold)
