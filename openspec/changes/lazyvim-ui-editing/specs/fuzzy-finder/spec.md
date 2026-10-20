## ADDED Requirements

### Requirement: Picker routing for LazyVim callers

Picker requests made through LazyVim's picker abstraction, by LazyVim core, its extras or user code, SHALL be routed to KoalaVim's file finder for file search and to KoalaVim's live grep for text search, honoring any requested working directory. All other picker requests SHALL be handled by the general fuzzy picker with KoalaVim's layout.

#### Scenario: LazyVim requests file search
- **WHEN** a LazyVim component requests the `files` picker with a specific working directory
- **THEN** KoalaVim's file finder SHALL open scoped to that directory

#### Scenario: LazyVim requests live grep
- **WHEN** a LazyVim component requests the `live_grep` picker
- **THEN** KoalaVim's live grep SHALL open

#### Scenario: Other picker requests
- **WHEN** a LazyVim component requests a picker such as recent files or git files
- **THEN** the general fuzzy picker SHALL open with KoalaVim's layout
