## ADDED Requirements

### Requirement: Contested keys resolve per flavor

Every key bound by both LazyVim and KoalaVim to different actions SHALL resolve to exactly one action, chosen by the active flavor: KoalaVim's action under `koala`, LazyVim's action under `lazyvim`. The set of contested keys and their per-flavor resolution SHALL be defined in a single table that drives the implementation and the verification.

#### Scenario: Koala flavor collision
- **WHEN** the flavor is `koala` and the user presses `<leader>l`
- **THEN** the diagnostics display mode SHALL cycle (KoalaVim) and the plugin manager UI SHALL NOT open

#### Scenario: LazyVim flavor collision
- **WHEN** the flavor is `lazyvim` and the user presses `<leader>l`
- **THEN** the plugin manager UI SHALL open (LazyVim)

### Requirement: No ambiguous leader prefixes

In each mode, no key sequence in the leader namespace SHALL be both a complete mapping and a strict prefix of another mapping, except for explicitly allowlisted modal sub-mode bodies. A verification command SHALL report any violation for the active flavor.

#### Scenario: Black-hole delete is not hijacked
- **WHEN** the flavor is `koala` and the user types `<leader>dw`
- **THEN** a word SHALL be deleted into the black-hole register and no debugger action SHALL run

#### Scenario: Verification reports violations
- **WHEN** a keymap that creates an ambiguous prefix is added and the verification command runs
- **THEN** the command SHALL report the conflicting key sequences

### Requirement: Koala flavor relocates LazyVim groups

Under the `koala` flavor, LazyVim key groups whose prefix collides with a KoalaVim key SHALL be moved instead of dropped: code actions from `<leader>c` to `<leader>v`, debugging from `<leader>d` to `<leader>r`, search pickers into `<leader>f`, buffer management from `<leader>b` to `<leader>q`, and plugin-manager commands to `<leader>z`. This SHALL include keys contributed by language extras and LSP server key lists. Keys whose capability gating applies (only shown when the server supports the method) SHALL keep that gating after relocation.

#### Scenario: Relocated LSP key
- **WHEN** the flavor is `koala` and a server that supports organize-imports is attached
- **THEN** organize imports SHALL be available on `<leader>vo` and not on `<leader>co`

#### Scenario: Relocated language-extra key
- **WHEN** the flavor is `koala` and a Python file is open
- **THEN** the virtual-environment selector SHALL be available on `<leader>vv`

#### Scenario: Relocated search picker
- **WHEN** the flavor is `koala` and the user presses `<leader>fh`
- **THEN** the help-pages picker SHALL open

### Requirement: Koala flavor keeps vim defaults

Under the `koala` flavor, LazyVim's remaps of built-in vim keys that KoalaVim does not remap itself SHALL NOT be active.

#### Scenario: H keeps its vim meaning
- **WHEN** the flavor is `koala` and the user presses `H` in normal mode
- **THEN** the cursor SHALL move to the top of the window rather than switching buffers

### Requirement: Koala flavor has no duplicate bindings

Under the `koala` flavor, a LazyVim binding SHALL be removed when KoalaVim provides the same action on a different key.

#### Scenario: Format key
- **WHEN** the flavor is `koala`
- **THEN** formatting SHALL be bound to KoalaVim's format key and LazyVim's `<leader>cf` SHALL NOT be bound

### Requirement: LazyVim flavor keeps KoalaVim features

Under the `lazyvim` flavor, KoalaVim keys for features that LazyVim does not provide SHALL remain bound. KoalaVim keys that only duplicate a LazyVim action SHALL be removed. A KoalaVim feature whose key is taken by LazyVim SHALL be bound to an alternative key.

#### Scenario: KoalaVim-only feature kept
- **WHEN** the flavor is `lazyvim` and the user presses `<M-e>`
- **THEN** a smart vertical split SHALL be created

#### Scenario: Displaced feature relocated
- **WHEN** the flavor is `lazyvim` and the user presses `<leader>uv`
- **THEN** the diagnostics display mode SHALL cycle

#### Scenario: Duplicate removed
- **WHEN** the flavor is `lazyvim`
- **THEN** KoalaVim's `<leader>h*` hunk keys SHALL NOT be bound, and the hunk actions SHALL be on LazyVim's `<leader>gh*`

### Requirement: Flavor-specific key group labels

The key-binding popup SHALL show group labels that match the active flavor's layout, with no label for a group that does not exist in that flavor.

#### Scenario: Koala flavor groups
- **WHEN** the flavor is `koala` and the user presses the leader key
- **THEN** the popup SHALL label `v` as code and `r` as run/debug, and SHALL NOT show a `c` code group or an `s` search group

### Requirement: No KoalaVim-internal key clashes

KoalaVim SHALL NOT bind the same key to different actions in overlapping scopes (global vs global, or global vs a buffer-local mapping that shadows it unintentionally).

#### Scenario: Notification history in C files
- **WHEN** a C file is open and the user triggers the notification-history key
- **THEN** notification history SHALL open
