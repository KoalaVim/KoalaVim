## 1. Config

- [x] 1.1 Add `"tsgo": { "enabled": false }` to `lsp` section in `default_kvim.conf`
- [x] 1.2 Add `lsp.tsgo` schema with `enabled` boolean property to `config_scheme.jsonc`

## 2. Deferred server registration

- [x] 2.1 Add `LSP_LAZY_SERVERS` global in `globals.lua` for config-dependent server registration
- [x] 2.2 In `general.lua`, resolve `LSP_LAZY_SERVERS` into `LSP_SERVERS` before the server setup loop
- [x] 2.3 In `typescript.lua`, register a resolver in `LSP_LAZY_SERVERS` that returns `'tsgo'` or `'vtsls'` with shared opts based on `conf.lsp.tsgo.enabled`
- [x] 2.4 Extract inlay hints to a shared local variable used by both branches
- [x] 2.5 Move `vtsls.max_memory` config from `general.lua` into the resolver's vtsls branch

## 3. Health check

- [x] 3.1 In the resolver, warn via `KoalaVim.health` when `tsgo.enabled` is true but `tsgo` is not executable
