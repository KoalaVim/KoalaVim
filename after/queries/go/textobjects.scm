; extends

;; Binary expression
(binary_expression) @binary_expression.inner
(unary_expression) @binary_expression.inner

;; Function name
(function_declaration
  name: (_)? @function.name)

(method_declaration
  name: (_)? @function.name)
