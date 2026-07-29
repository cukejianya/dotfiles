; Inject SQL inside string literals explicitly marked for SQL
; ((string_literal (multiline_string_fragment)) @injection.content
; (#lua-match? @injection.content "^SELECT")
; (#set! injection.include-children)
; (#set! injection.language "sql"))
(
 (annotation
   name: (identifier) @_annotation
   arguments:
  arguments: (annotation_argument_list
    .
    (string_literal
      .
      (_) @injection.content)))
  (#any-of? @_annotation "SqlQuery" "SqlUpdate")
  (#set! injection.language "sql")
)

(
 (multiline_string_fragment) @injection.content
  (#match? @injection.content "(SELECT|INSERT|UPDATE|WHERE)")
  (#set! injection.language "sql")
)
