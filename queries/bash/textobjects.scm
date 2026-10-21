; extends

; Shell pipe, used by `i|`/`a|` (was `shellPipe` in nvim-various-textobjs)
(pipeline (command) @pipeline.inner @pipeline.outer "|" @pipeline.outer)
