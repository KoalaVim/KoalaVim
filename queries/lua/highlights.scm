;; extends

; Override function table fields to be @field instead of @function
(table_constructor
  (field
    name: (identifier) @field
    value: (function_definition)))

