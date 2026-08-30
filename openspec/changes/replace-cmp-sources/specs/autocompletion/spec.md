## MODIFIED Requirements

### Requirement: Multi-source completion engine

The system SHALL provide autocompletion with multiple sources in priority order: LSP (highest), file paths (fuzzy), snippets, visible buffers (fuzzy), dictionary, and calculator. Completion SHALL trigger automatically and be manually invocable.

#### Scenario: LSP completion prioritized
- **WHEN** both LSP and buffer sources offer completions for the same prefix
- **THEN** LSP completions SHALL appear above buffer completions in the menu

#### Scenario: Manual trigger
- **WHEN** the user presses the manual completion trigger key
- **THEN** the completion menu SHALL appear with all available completions

#### Scenario: Fuzzy buffer matching
- **WHEN** the user types a partial word that fuzzy-matches content in visible buffers
- **THEN** matching buffer words SHALL appear in completions even if the prefix is not exact

#### Scenario: Fuzzy path matching
- **WHEN** the user types a partial file path
- **THEN** matching paths SHALL appear in completions using fuzzy matching

#### Scenario: Cross-platform dictionary completion
- **WHEN** the user types at least 3 characters matching a dictionary word
- **THEN** dictionary completions SHALL appear regardless of operating system (macOS, Linux)

## REMOVED Requirements

### Requirement: System dictionary lookup via cmp-look
**Reason**: Replaced by cmp-dictionary which provides cross-platform dictionary completion without requiring `/usr/share/dict/words`
**Migration**: Dictionary completions now served by `cmp-dictionary` source (source name: `dictionary` instead of `look`)
