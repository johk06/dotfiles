; extends

; Inject jq code
(command
  name: (command_name) @_command
  argument: [
    (string
      (string_content) @injection.content)
    (concatenation
      (string
        (string_content) @injection.content))
    (raw_string) @injection.content
    (concatenation
      (raw_string) @injection.content)
  ]
  (#any-of? @_command "jq" "xq" "yq" "tomlq")
  (#offset! @injection.content 0 1 0 -1)
  (#set! injection.language "jq"))

; Basically the same for awk
(command
  name: (command_name) @_command
  argument: [
    (string
      (string_content) @injection.content)
    (concatenation
      (string
        (string_content) @injection.content))
    (raw_string) @injection.content
    (concatenation
      (raw_string) @injection.content)
  ]
  (#any-of? @_command "awk" "gawk" "mawk" "nawk")
  (#offset! @injection.content 0 1 0 -1)
  (#set! injection.language "awk"))

; All other languages that take a -c argument
((command
  name: (command_name) @_command @injection.language
  argument: (word) @_arg
  argument: [
    (string) @injection.content
    (concatenation
      (string) @injection.content)
    (raw_string) @injection.content
    (concatenation
      (raw_string) @injection.content)
  ])
  (#any-of? @_command "sh" "bash" "python")
  (#eq? @_arg "-c")
  (#offset! @injection.content 0 1 0 -1)
  (#set! injection.include-children))
