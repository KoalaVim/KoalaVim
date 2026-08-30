## 1. Replace cmp-buffer with cmp-fuzzy-buffer

- [x] 1.1 Add `tzachar/cmp-fuzzy-buffer` and `romgrk/fuzzy.nvim` plugin specs (fuzzy.nvim is a shared dependency for both fuzzy plugins)
- [x] 1.2 Replace `hrsh7th/cmp-buffer` dependency in nvim-cmp with `tzachar/cmp-fuzzy-buffer`
- [x] 1.3 Update `all_visible_buffers_source()` helper to use `fuzzy_buffer` source name and adapt `get_bufnrs` option
- [x] 1.4 Update cmdline `/` search source to use `fuzzy_buffer`

## 2. Replace cmp-path with cmp-fuzzy-path

- [x] 2.1 Add `tzachar/cmp-fuzzy-path` plugin spec
- [x] 2.2 Replace `hrsh7th/cmp-path` dependency in nvim-cmp with `tzachar/cmp-fuzzy-path`
- [x] 2.3 Update path source entries in `cmp.setup()` sources to use `fuzzy_path` name with trailing_slash option
- [x] 2.4 Update cmdline `:` source to use `fuzzy_path` instead of `path`

## 3. Replace cmp-look with cmp-dictionary

- [x] 3.1 Add `uga-rosa/cmp-dictionary` plugin spec
- [x] 3.2 Remove `octaltree/cmp-look` from nvim-cmp dependencies
- [x] 3.3 Replace `look` source entry with `dictionary` source in `cmp.setup()` sources, preserving priority and keyword_length settings

## 4. Add filemention.nvim

- [x] 4.1 Add `not-manu/filemention.nvim` plugin spec with appropriate lazy-loading event
