## MODIFIED Requirements

### Requirement: Snippet support

The system SHALL support VSCode-format snippets expanded by Neovim's native snippet engine, with tab-stop navigation. Snippets that the native parser cannot handle SHALL still insert a readable preview instead of failing. Tab SHALL select the next completion menu item when the menu is visible. Otherwise it SHALL jump to the next snippet placeholder when a snippet is active. Otherwise it SHALL accept a pending AI suggestion when one is available, and fall back to a literal tab. Shift-tab SHALL select the previous menu item or jump to the previous placeholder.

#### Scenario: Expand and navigate snippet
- **WHEN** the user confirms a snippet completion and presses tab with the completion menu closed
- **THEN** the snippet SHALL be expanded and the cursor SHALL move to the next placeholder

#### Scenario: Tab without active snippet
- **WHEN** the completion menu is visible and no snippet is active
- **THEN** tab SHALL select the next item in the completion menu

#### Scenario: Shift-tab in snippet
- **WHEN** a snippet is active, the completion menu is closed, and the user presses shift-tab
- **THEN** the cursor SHALL move to the previous placeholder

#### Scenario: Tab with nothing to do
- **WHEN** the completion menu is closed, no snippet is active and no AI suggestion is pending
- **THEN** tab SHALL insert a literal tab (or indentation)

### Requirement: Language-specific snippets

The system SHALL ship curated snippet collections in VSCode format for common languages (C/C++, Go, Lua, Python), covering frequent patterns like struct definitions, error handling, main functions and interface checks. These SHALL be available alongside the community friendly-snippets collection.

#### Scenario: Go snippet expansion
- **WHEN** the user triggers a Go snippet for struct definition
- **THEN** a struct template SHALL expand with placeholders for the struct name and fields

#### Scenario: Community snippets available
- **WHEN** the user types the prefix of a friendly-snippets entry for the current filetype
- **THEN** that snippet SHALL be offered in the completion menu
