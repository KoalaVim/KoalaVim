## Purpose

Code editing capabilities enhance the act of writing and manipulating code: smart commenting, surround operations, multi-cursor editing, text exchange, auto-pairs, yank ring, split/join, sibling swap, word toggling, enhanced motions, and extended text objects.

## Requirements

### Requirement: Smart commenting

The system SHALL provide toggle-comment operations for lines and selections. Comment style SHALL be determined by treesitter context, correctly handling embedded languages (e.g., JSX inside TSX).

#### Scenario: Comment embedded language
- **WHEN** the cursor is inside a JSX block within a TSX file and the user triggers line-comment
- **THEN** the comment SHALL use `{/* */}` JSX comment syntax, not `//` TypeScript syntax

### Requirement: Text exchange

The system SHALL provide operators to exchange two text regions. The first invocation marks a region; the second swaps the marked region with the new selection.

#### Scenario: Exchange two words
- **WHEN** the user marks a word with the exchange operator, moves to another word, and triggers exchange again
- **THEN** the two words SHALL swap positions

### Requirement: Auto-pairs

The system SHALL automatically insert matching closing characters (brackets, quotes, etc.) when an opening character is typed. Pair behavior SHALL be treesitter-aware to avoid false completions inside strings or comments.

#### Scenario: Insert closing bracket
- **WHEN** the user types `(` in a code context
- **THEN** `)` SHALL be inserted after the cursor

#### Scenario: Suppress in string
- **WHEN** the user types `(` inside a string literal
- **THEN** the system SHALL respect treesitter context for whether to auto-pair

### Requirement: Line peek

The system SHALL preview the target line when typing a line number in command mode (`:N`), without moving the cursor permanently.

#### Scenario: Preview line during input
- **WHEN** the user types `:42` in command mode
- **THEN** line 42 SHALL be temporarily visible/highlighted without committing the jump

### Requirement: Two-character jump

The system SHALL allow jumping to any visible position on screen by typing two characters that match text at the target location.

#### Scenario: Jump to match
- **WHEN** the user triggers jump mode and types two characters
- **THEN** all matching positions SHALL be labeled and the user can select one to jump to

### Requirement: Enhanced character motions

`f`, `F`, `t`, `T` motions SHALL work across multiple lines (not just the current line) and SHALL display labels for ambiguous matches.

#### Scenario: Multi-line f motion
- **WHEN** the user presses `f` followed by a character that appears on multiple lines
- **THEN** matches beyond the current line SHALL be reachable via labels

### Requirement: Word toggling

The system SHALL toggle common opposite words under the cursor (true/false, prev/next, before/after, start/end, vertical/horizontal, enable/disable, etc.).

#### Scenario: Toggle boolean
- **WHEN** the cursor is on `true` and the user triggers word toggle
- **THEN** the word SHALL change to `false`

### Requirement: Yank ring

The system SHALL maintain a ring of past yanks. After pasting, the user SHALL be able to cycle through previous yank entries to replace the just-pasted text. Visual-mode paste SHALL replace the selection without overwriting the yank register.

#### Scenario: Cycle yanks after paste
- **WHEN** the user pastes text and then presses the yank-cycle key
- **THEN** the pasted text SHALL be replaced with the previous entry in the yank ring

#### Scenario: Visual paste preserves register
- **WHEN** the user selects text in visual mode and pastes
- **THEN** the selected text SHALL be deleted to the black-hole register, preserving the paste register contents

### Requirement: Surround operations

The system SHALL support adding, changing, and deleting surrounding pairs (brackets, quotes, tags) via operators. Shortcuts SHALL exist for common operations: surround word, surround WORD, and quick bracket/quote type changes.

#### Scenario: Surround a word with brackets
- **WHEN** the user triggers the surround-word shortcut followed by `(`
- **THEN** the word under the cursor SHALL be wrapped in `(` and `)`

#### Scenario: Change surrounding quotes
- **WHEN** the cursor is inside `'hello'` and the user triggers change-surround from `'` to `"`
- **THEN** the text SHALL become `"hello"`

### Requirement: Treesitter-based split and join

The system SHALL support splitting single-line code constructs (function arguments, array items, object properties) across multiple lines and joining multi-line constructs back to a single line, using treesitter to understand structure.

#### Scenario: Split function arguments
- **WHEN** the cursor is on `foo(a, b, c)` and the user triggers split
- **THEN** each argument SHALL be placed on its own indented line

#### Scenario: Join back to single line
- **WHEN** the cursor is on a multi-line argument list and the user triggers join
- **THEN** all arguments SHALL be collapsed to a single comma-separated line

### Requirement: Sibling swap

The system SHALL allow swapping treesitter sibling nodes (function arguments, list items, object properties) left and right.

#### Scenario: Swap arguments
- **WHEN** the cursor is on the second argument in `foo(a, b, c)` and the user triggers swap-right
- **THEN** the result SHALL be `foo(a, c, b)`

### Requirement: Extended text objects

The system SHALL provide text objects for: subwords (camelCase/snake_case segments), indent blocks, shell pipes, URLs, and enhanced argument/balanced-pair objects.

#### Scenario: Select subword
- **WHEN** the cursor is on `myVariableName` inside `Variable` and the user selects the inner-subword text object
- **THEN** `Variable` SHALL be selected

### Requirement: Multi-cursor editing

The system SHALL support VSCode/Sublime-style multi-cursor editing: add selection for the current word, add cursor above/below the current line. All cursors SHALL edit simultaneously.

#### Scenario: Add selection for word
- **WHEN** the user presses the add-selection key with the cursor on a word
- **THEN** the next occurrence of that word SHALL also be selected, with both editable simultaneously

#### Scenario: Add cursor below
- **WHEN** the user presses the add-cursor-below key
- **THEN** a new cursor SHALL appear on the line below at the same column

### Requirement: Block movement

The system SHALL allow moving visual block selections up, down, left, and right, shifting surrounding content to accommodate.

#### Scenario: Move selection down
- **WHEN** a visual selection covers lines 5-7 and the user triggers move-down
- **THEN** the selected lines SHALL move to lines 6-8, with the line previously at 8 moving to 5
