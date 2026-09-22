(shebang) @keyword.directive @nospell

(comment) @comment @spell

(number) @number

(word) @function

(string) @string

(raw_string) @string

(symbol) @symbol

(unquote) @macro

(string_escape) @string.escape

[
  "["
  "]"
] @punctuation.delimiter

((word) @operator
  (#any-of? @operator
    "+" "-" "*" "/" "^" "mod" "mod." "->" "=" "=~" "<" "<=" ">" ">=" "!=" "&=" "&!=" "-." "/." "^."
    "//" "+-" "-+"))

([
  (symbol)
  (string)
  (raw_string)
] @property
  .
  (word) @_word
  (#set! priority 110 @property)
  (#any-of? @_word "#of"))

((word) @keyword.function
  (#any-of? @keyword.function "<-" "<*-" "<#-" "&<-" "<%-" "<?-" "<,-"))

((word) @keyword.import
  (#any-of? @keyword.import
    "load" "load?" "loadstd" "import" "lazy-load" "require" "using" "use" "curate" "extract"
    "export" "import-from"))

((word) @function.call
  (#any-of? @function.call
    "apply" "keep" "keep2" "dip" "dip2" "dip3" "call." "apply?" "transmute" "transmute?" "fork"
    "fork2" "transform?" "then"))

((word) @keyword.conditional
  (#any-of? @keyword.conditional "if" "when" "unless" "select" "match"))

((word) @keyword.repeat
  (#any-of? @keyword.repeat
    "loop" "while" "-repeat" "repeat" "for+" "for-" "for*" "for" "foreach" "-foreach"))

((word) @boolean
  (#any-of? @boolean "true" "false" "nil"))

((word) @punctuation.special
  (#any-of? @punctuation.special "{" "}list" "}count" "}hash" "}#" "}," "}M" "}count?" ">{"))
