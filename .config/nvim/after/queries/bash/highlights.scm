; extends

; usually "--" as a command argument is more of a metasyntactic thing
(command
  argument: (word) @punctuation.delimiter
  (#eq? @punctuation.delimiter "--"))

; make bash "keywords" behave like other languages
(command
  name: (command_name
    (word)) @keyword.return
  (#any-of? @keyword.return "return" "exit" "break"))
