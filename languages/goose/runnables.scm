; A run button beside a program's `fn main`.
(
  (source_file
    (function_declaration
      name: (identifier) @run @_name
      (#eq? @_name "main")))
  (#set! tag goose-main)
)
