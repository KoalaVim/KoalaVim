## Purpose

Treesitter provides structural code understanding: automatic grammar installation, syntax highlighting, folding, structural text objects (functions, classes, blocks, parameters), structural navigation, incremental selection, sticky context headers, context-aware commenting, and enhanced matching.

## Requirements

### Requirement: Automatic grammar installation

The system SHALL automatically install and enable treesitter grammars for any filetype on first encounter. Syntax highlighting, folding, and indentation SHALL use treesitter when a grammar is available.

#### Scenario: Open new filetype
- **WHEN** the user opens a file with a filetype whose grammar is not yet installed
- **THEN** the grammar SHALL be automatically downloaded, compiled, and enabled for syntax highlighting

### Requirement: Treesitter-based folding

The system SHALL use treesitter expression-based folding as the default fold method. All folds SHALL start open by default.

#### Scenario: Folds available on open
- **WHEN** a file with a treesitter grammar is opened
- **THEN** folds SHALL be available at structural boundaries (functions, classes, blocks) and all SHALL be open

### Requirement: Structural text objects

The system SHALL provide treesitter-powered text objects for selecting code structures: functions (inner/outer), classes (inner/outer), blocks (inner/outer), loops (inner/outer), comments (inner/outer), calls (inner/outer), conditionals (inner/outer), binary expressions (inner), and function names (outer).

#### Scenario: Select inner function
- **WHEN** the cursor is inside a function body and the user selects the inner-function text object
- **THEN** the function body (excluding signature and closing) SHALL be selected

#### Scenario: Select outer class
- **WHEN** the cursor is inside a class and the user selects the outer-class text object
- **THEN** the entire class including its declaration and closing SHALL be selected

#### Scenario: Select binary expression
- **WHEN** the cursor is on a binary expression (e.g., `a && b`) and the user selects the inner-binary-expression text object
- **THEN** the binary expression SHALL be selected

### Requirement: Structural navigation

The system SHALL provide jump commands to navigate to the next/previous start/end of functions, classes, blocks, parameters, and calls.

#### Scenario: Jump to next function
- **WHEN** the user triggers next-function-start navigation
- **THEN** the cursor SHALL jump to the beginning of the next function definition

#### Scenario: Jump to previous class
- **WHEN** the user triggers previous-class navigation
- **THEN** the cursor SHALL jump to the beginning of the previous class definition

#### Scenario: Jump to next parameter
- **WHEN** the user triggers next-parameter navigation
- **THEN** the cursor SHALL jump to the next function parameter

### Requirement: Incremental selection

The system SHALL support expanding the selection incrementally based on treesitter node hierarchy. Each expansion SHALL select the next larger enclosing node. Shrinking the selection SHALL reverse the process.

#### Scenario: Expand selection
- **WHEN** the cursor is on a variable name and the user triggers expand-selection three times
- **THEN** the selection SHALL grow from the variable to the expression, to the statement, to the enclosing block

#### Scenario: Shrink selection
- **WHEN** a block is selected and the user triggers shrink-selection
- **THEN** the selection SHALL contract to the smaller node that was previously selected

### Requirement: Sticky context header

The system SHALL show the enclosing function, class, or block signature at the top of the window when the definition line has scrolled off-screen. This provides persistent context about the current scope.

#### Scenario: Function scrolled off-screen
- **WHEN** the cursor is deep inside a long function whose signature has scrolled above the viewport
- **THEN** the function signature SHALL be displayed in a sticky header at the top of the window

### Requirement: Context-aware comment strings

The system SHALL determine the correct comment syntax based on treesitter context, handling embedded languages correctly (e.g., different comment styles for HTML vs. JavaScript within the same file).

#### Scenario: Comment in embedded language
- **WHEN** the cursor is inside a `<script>` block in an HTML file and commenting is triggered
- **THEN** the comment SHALL use `//` JavaScript syntax, not `<!-- -->` HTML syntax

### Requirement: JSON path display

The system SHALL show the JSON path to the treesitter node under the cursor when editing JSON files. The path SHALL be copyable to the clipboard.

#### Scenario: Show JSON path
- **WHEN** the cursor is on a deeply nested key in a JSON file
- **THEN** the JSON path (e.g., `$.config.editor.indent.tab_size`) SHALL be displayed and available for copying

### Requirement: Enhanced matching

The system SHALL provide treesitter-aware `%` matching that works for language-specific constructs (if/else/end, opening/closing tags, do/end blocks) beyond simple bracket matching.

#### Scenario: Match if/end
- **WHEN** the cursor is on an `if` keyword and the user presses `%`
- **THEN** the cursor SHALL jump to the matching `end` (or `else`/`elseif`)

### Requirement: Auto end-wise completion

The system SHALL automatically insert matching end keywords (`end`, `fi`, `done`, `endif`, etc.) when the user starts a block construct in languages that use keyword-delimited blocks (Ruby, Lua, Bash, Vim script, etc.).

#### Scenario: Auto-insert end in Lua
- **WHEN** the user types `function foo()` and presses Enter in a Lua file
- **THEN** `end` SHALL be automatically inserted on the appropriate closing line

### Requirement: Custom language highlights

The system SHALL support custom treesitter highlight overrides per language to fine-tune syntax coloring beyond the default grammar rules.

#### Scenario: Go keyword highlighting
- **WHEN** a Go file is opened
- **THEN** `chan` and `map` SHALL be highlighted as keywords (not identifiers)
