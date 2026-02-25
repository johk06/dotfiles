; TODO: remove once nvim-treesitter-textobjects adds typst queries

(call
  (content
    "[" @parameter.outer
    (_) @parameter.inner
    "]" @parameter.outer))

(call
  (formula) @parameter.inner @parameter.outer
  ","? @parameter.outer)

(group
  (_) @parameter.inner @parameter.outer
  ","? @parameter.outer)

(number) @number.inner

(let
  pattern: (_) @assignment.lhs
  value: (_) @assignment.inner @assignment.rhs) @assignment.outer

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
  value: (_) @function.inner) @function.outer

(lambda
  pattern: (_) @parameter.inner @parameter.outer
  ","? @parameter.outer)

(let
  pattern: (call)
  value: (_) @function.inner) @function.outer

(comment) @comment.outer
