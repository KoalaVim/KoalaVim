## MODIFIED Requirements

### Requirement: Extended text objects

The system SHALL provide text objects for: subwords (camelCase/snake_case segments), indent blocks, shell pipes, URLs, enhanced argument/balanced-pair objects, and treesitter/pattern objects for function, class, code block, HTML tag, digits, case-aware word, whole buffer and function call ("usage"). Object keys SHALL NOT collide with each other.

#### Scenario: Select subword
- **WHEN** the cursor is on `myVariableName` inside `Variable` and the user selects the inner-subword text object
- **THEN** `Variable` SHALL be selected

#### Scenario: Select function body
- **WHEN** the cursor is inside a function and the user selects the inner-function text object
- **THEN** the function body SHALL be selected

#### Scenario: Select whole buffer
- **WHEN** the user applies an operator with the whole-buffer text object
- **THEN** the operator SHALL apply to the entire buffer content
