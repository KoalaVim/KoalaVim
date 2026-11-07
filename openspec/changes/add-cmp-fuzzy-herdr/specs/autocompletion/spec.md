## ADDED Requirements

### Requirement: Herdr completion accompanies fuzzy buffer completion
KoalaVim SHALL load `KoalaVim/cmp-fuzzy-herdr` alongside `cmp-fuzzy-buffer` and include `fuzzy_herdr` wherever it configures the fuzzy buffer source: general insert completion, search command-line completion, debug watch completion, and Cargo.toml completion. Where source priorities are specified, Herdr completion SHALL rank below buffer completion and above dictionary completion. Existing buffer completion SHALL remain available outside Herdr.

#### Scenario: General completion in Herdr
- **WHEN** both visible buffers and other Herdr panes contain candidates during insert completion
- **THEN** both sources SHALL participate with Herdr source priority below buffer and above dictionary

#### Scenario: Specialized buffer completion contexts
- **WHEN** the user requests completion in search, debug watches, or Cargo.toml
- **THEN** the configured Herdr source SHALL participate alongside the existing buffer source

#### Scenario: Completion outside Herdr
- **WHEN** KoalaVim enables fuzzy buffer completion outside Herdr
- **THEN** buffer completion SHALL continue normally while Herdr completion remains inactive
