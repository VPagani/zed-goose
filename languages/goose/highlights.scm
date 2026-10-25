; Goose highlighting, with Zed's capture names. Adapted from the upstream query
; (tree-sitter/queries/highlights.scm in aardappel/goose), which uses
; nvim-style names. Later patterns win where two cover the same bytes, so the
; broad rules come first. Where a pattern names two captures, Zed tries the
; right one first and falls back to the left one when a theme has no style
; for it.

(identifier) @variable

; The implicit parameter of a function value without a parameter list.
((identifier) @variable.special
 (#eq? @variable.special "it"))

(parameter name: (identifier) @variable.parameter)
(function_value_parameter name: (identifier) @variable.parameter)

(field_declaration name: (identifier) @property)
(field_expression field: (identifier) @property)
(field_initializer name: (identifier) @property)

(namespace_declaration name: (identifier) @type @namespace)
(import_path (identifier) @type @namespace)
(scoped_identifier namespace: (identifier) @type @namespace)

(function_declaration name: (identifier) @function)
(function_declaration name: (scoped_identifier name: (identifier) @function))
(extern_member name: (identifier) @function)
(extern_member name: (scoped_identifier name: (identifier) @function))
(call_expression function: (identifier) @function)
(call_expression function: (scoped_identifier name: (identifier) @function))
; A call through a dot is a method call or a call of a free function by UFCS.
(call_expression function: (field_expression field: (identifier) @function.method))
(return_expression target: (identifier) @function)
(return_expression target: (scoped_identifier name: (identifier) @function))

(struct_declaration name: (identifier) @type)
(struct_declaration name: (scoped_identifier name: (identifier) @type))
(enum_declaration name: (identifier) @type @enum)
(enum_declaration name: (scoped_identifier name: (identifier) @type @enum))
(type_alias_declaration name: (identifier) @type)
(type_alias_declaration name: (scoped_identifier name: (identifier) @type))
(type_parameter name: (identifier) @type)
(named_type name: (identifier) @type)
(named_type name: (scoped_identifier name: (identifier) @type))
(index_type domain: (identifier) @variable)
(struct_literal name: (identifier) @type)
(struct_literal name: (scoped_identifier name: (identifier) @type))
(primitive_type) @type.builtin

(enum_variant name: (identifier) @constant @variant)
(variant_type variant: (identifier) @constant @variant)
(struct_literal variant: (identifier) @constant @variant)
(variant_pattern variant: (identifier) @constant @variant)
(pattern_list (identifier) @constant @variant)
(range_pattern (identifier) @constant @variant)
(negative_pattern (identifier) @constant @variant)

; A payload-less variant: Shape.Dot. Types and variants are PascalCase by
; convention, which separates them from a field read.
((field_expression value: (identifier) @type field: (identifier) @constant @variant)
 (#match? @type "^[A-Z]")
 (#match? @constant "^[A-Z]"))

; ALL_CAPS names are constants by convention.
((identifier) @constant
 (#match? @constant "^_*[A-Z][A-Z0-9_]+$"))

(wildcard_pattern) @variable.special
(self) @variable.special

(function_modifier) @keyword
(function_modifier (string_literal) @string)

[
  "fn"
  "thread_fn"
  "struct"
  "enum"
  "type"
  "let"
  "var"
  "const"
  "pad"
  "reusable"
  "namespace"
  "block"
  "fields"
  "variants"
  "types"
  "in"
  "upto"
  "extern"
  "as"
  "import"
  "from"
  "return"
  "if"
  "else"
  "match"
  "guard"
  "while"
  "for"
  "loop"
  "break"
  (continue_expression)
] @keyword

(boolean_literal) @boolean
(null) @constant.builtin
(int_literal) @number
(float_literal) @number
(char_literal) @string.special
(string_literal) @string
(raw_string_literal) @string
(escape_sequence) @string.escape

[
  "=" ".="
  "+" "-" "*" "/" "%"
  "==" "!=" ".==" ".!=" "<" "<=" ">" ">="
  "&&" "||" "!"
  "&" "|" "^" "~" "<<" ">>"
  "+=" "-=" "*=" "/=" "%="
  "&=" "|=" "^=" "<<=" ">>="
  "++" "--"
  "->" "=>"
  ".."
  "?"
] @operator

[
  "(" ")" "[" "]" "{" "}"
] @punctuation.bracket

(type_parameters ["<" ">"] @punctuation.bracket)
(type_arguments ["<" ">"] @punctuation.bracket)

[
  "," ";" ":" "::" "."
] @punctuation.delimiter

(line_comment) @comment
(block_comment) @comment
