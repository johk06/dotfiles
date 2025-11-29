; the default asm highlighting is all over the place
; so explicitly not: ; extends

(instruction
  (ident) @label)

(instruction
  (ident
    (reg) @variable))


(instruction
  kind: (_) @function)

(instruction
  kind: (_) @keyword.return
  (#any-of? @keyword.return "ret" "leave" "syscall"))

(instruction
  kind: (_) @keyword
  (ident (reg (word) @function))
  (#eq? @keyword "call"))

(meta
  kind: (_) @property)

(label) @label
(address) @label

(int) @number
(string) @string

[
 ","
 ":"
 ] @punctuation.delimiter

[
 "+"
 "-"
 "*"
 "/"
 "%"
 "|"
 "^"
 "&"
 ] @operator

[
 "("
 ")"
 "["
 "]"
 ] @punctuation.bracket

[
 (line_comment)
 (block_comment)
 ] @comment @spell
