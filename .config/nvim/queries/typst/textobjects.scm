; nvim-treesitter doesn't ship any textobject queries for typst yet
; TODO: remove once nvim-treesitter-textobjects adds typst queries
(number) @number.inner

(let
  pattern: (_) @assignment.lhs
  value: (_) @assignment.inner @assignment.rhs) @assignment.outer

(let
  pattern: (call)
  value: (_) @function.inner) @function.outer

(comment) @comment.outer

; Variations on function calls {{{
; Content literal call {{{1
(call
  .
  (content
    "["
    _+ @call.inner
    "]")) @call.outer

(call
  (content
    "[" @parameter.outer
    (_) @parameter.inner
    "]" @parameter.outer))

; }}}
(call
  (formula) @parameter.inner @parameter.outer
  ","? @parameter.outer)

(call
  "("
  _+ @call.inner
  ")") @call.outer

(call
  (group
    "("
    _+ @call.inner
    ")")) @call.outer

(group
  .
  (_) @parameter.inner @parameter.outer
  .
  ","? @parameter.outer)

(group
  "," @parameter.outer
  .
  (_) @parameter.inner @parameter.outer)

; }}}
; Control flow {{{
(branch
  condition: (_) @conditional.inner) @conditional.outer

(branch
  (block) @conditional.inner
  (#offset! @conditional.inner 0 1 0 -1))

(while
  condition: (_) @loop.inner) @loop.outer

(while
  (block) @loop.inner
  (#offset! @loop.inner 0 1 0 -1))

(for
  pattern: (_) @loop.inner
  value: (_) @loop.inner) @loop.outer

(for
  (block) @loop.inner
  (#offset! @loop.inner 0 1 0 -1))

((block) @block.inner @block.outer
  (#offset! @block.inner 0 1 0 -1))

(lambda
  value: [
    (block
      "{"
      _+ @function.inner
      "}")
    (_) @function.inner
  ]) @function.outer

(lambda
  pattern: (_) @parameter.inner @parameter.outer
  ","? @parameter.outer)

; }}}
; Custom Typst-Specific things
(math
  "$" @environment.outer
  _+ @environment.inner
  "$" @environment.outer)

; Markdown also uses "classes" for sections
(section
  (heading)
  .
  _+ @class.inner) @class.outer
