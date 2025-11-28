; extends

((format
  (type) @_type
  (#any-of? @_type "u" "d" "i" "u" "o" "x" "X" "b"))) @number

((format
  (type) @_type
  (#any-of? @_type "f" "F" "e" "E" "g" "G" "a" "A"))) @float

((format
  (type) @_type
  (#any-of? @_type "p" "n"))) @symbol

((format
  (type) @_type
  (#any-of? @_type "s" "c"))) @string

(format
  (flags) @constant)
