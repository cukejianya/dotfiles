; Treesitter folding query for functions and methods

(method_declaration (block) @fold)

(lambda_expression (block) @fold)

(constructor_declaration [(formal_parameters) (constructor_body)] @fold)
