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

(plan
  (entry
    name: (entry_name) @org.keyword.done)
  (#eq? @org.keyword.done "CLOSED")
  (#set! conceal "$"))

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

; The :CUSTOM_ID: property is the most common, but it looks horrendous
(property
  ":" @punctuation.delimiter
  name: (_) @property
  ":" @punctuation.delimiter
  value: (_) @constant
  (#eq? @property "CUSTOM_ID")
  (#set! @property conceal "#")
  (#set! @punctuation.delimiter conceal ""))

; Make the begin and end markers less obtrusive
(property_drawer
  ":properties:" @punctuation.delimiter.start
  ":end:" @punctuation.delimiter.end
  (#set! @punctuation.delimiter.start conceal "{")
  (#set! @punctuation.delimiter.end conceal "}"))

; Similar thing for the logbook
(drawer
  ":" @punctuation.delimiter.start
  name: (_) @label
  ":" @punctuation.delimiter.hide
  (#eq? @label "LOGBOOK")
  ":end:" @punctuation.delimiter.end
  (#set! @punctuation.delimiter.hide conceal "")
  (#set! @punctuation.delimiter.start conceal "{")
  (#set! @punctuation.delimiter.end conceal "}"))

(drawer
  name: (_) @_name
  contents: (contents
    (expr) @org.keyword.todo
    (#eq? @_name "LOGBOOK")
    (#eq? @org.keyword.todo "CLOCK:")
    (#set! @org.keyword.todo conceal "@")))

; Analogous, but leave the type of block there
(block
  "#+begin_" @punctuation.delimiter.start
  "#+end_" @punctuation.delimiter.end
  (#set! @punctuation.delimiter.start conceal "{")
  (#set! @punctuation.delimiter.end conceal "}"))

; Footnotes can obstruct a lot of screen real estate otherwise
(expr
  "[" @_conceal
  "str" @_name
  ":" @punctuation.delimiter
  "]" @_conceal
  (#eq? @_name "fn")
  (#set! @_name conceal "")
  (#set! @_conceal conceal "")
  (#set! @punctuation.delimiter conceal "^"))
