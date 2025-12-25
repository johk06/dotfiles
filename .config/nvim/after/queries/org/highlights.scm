; extends

; Show :property value as a key-value pair
(block
  parameter: (expr) @property
  (#lua-match? @property "^:"))

; Highlight code language
(block
  (expr) @_name
  .
  (expr) @label
  (#eq? @_name "src"))

; Show title as heading
(directive
  name: (expr) @_name
  value: (value) @markup.heading @spell
  (#eq? @_name "title"))

; Show author differently too
(directive
  name: (expr) @_name
  value: (value) @constant
  (#eq? @_name "author"))

; Make plan keywords less annoying
(plan
  (entry
    name: (entry_name) @org.keyword.todo)
  (#eq? @org.keyword.todo "SCHEDULED")
  (#set! conceal "@"))

(plan
  (entry
    name: (entry_name) @org.keyword.deadline)
  (#eq? @org.keyword.deadline "DEADLINE")
  (#set! conceal "!"))

; Make timestamps less annoying
(timestamp
  [
    "<"
    ">"
    "["
    "]"
  ] @punctuation.delimiter)

; Avoid spell checking, day names are the same regardless of spell language
(timestamp
  day: (day) @org.timestamp.day @nospell)

; Make the colons less annoying :)
(tag_list
  ":" @punctuation.delimiter)
