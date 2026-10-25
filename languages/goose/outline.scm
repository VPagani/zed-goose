(namespace_declaration
  "namespace" @context
  name: (_) @name) @item

(struct_declaration
  "struct" @context
  name: (_) @name
  type_parameters: (type_parameters)? @context) @item

(field_declaration
  name: (_) @name
  ":" @context
  type: (_) @context) @item

(enum_declaration
  "enum" @context
  name: (_) @name
  type_parameters: (type_parameters)? @context) @item

(enum_variant
  name: (_) @name) @item

(type_alias_declaration
  "type" @context
  name: (_) @name) @item

(function_declaration
  (function_modifier)* @context
  ["fn" "thread_fn"] @context
  name: (_) @name
  type_parameters: (type_parameters)? @context
  parameters: (parameters
    "(" @context
    ")" @context)) @item

(extern_block
  "extern" @context
  library: (_) @name) @item

(extern_member
  "fn" @context
  name: (_) @name
  parameters: (parameters
    "(" @context
    ")" @context)) @item

(source_file
  (variable_declaration
    ["let" "var" "const"] @context
    name: (_) @name) @item)
