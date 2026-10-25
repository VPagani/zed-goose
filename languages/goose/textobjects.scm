(function_declaration
  body: (block
    "{"
    (_)* @function.inside
    "}")) @function.around

; Externs and other declarations without a body.
(function_declaration
  !body) @function.around

(extern_member) @function.around

(struct_declaration
  body: (field_declaration_list
    "{"
    (_)* @class.inside
    "}")) @class.around

(enum_declaration
  "{"
  (_)* @class.inside
  "}") @class.around

(extern_block
  "{"
  (_)* @class.inside
  "}") @class.around

(line_comment)+ @comment.around

(block_comment) @comment.around
