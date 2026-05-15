; extends

(for) @context

(let) @context

(call
  item: (_) @_name
  (#any-of? @_name "figure" "table" "columns" "grid")) @context
