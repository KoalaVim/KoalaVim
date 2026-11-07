## Purpose

Provide fuzzy completion candidates from other Herdr terminal panes, including scrollback, with configurable selection and responsive capture.

## ADDED Requirements

### Requirement: Default pane selection and history
The plugin SHALL expose the `fuzzy_herdr` completion source. By default it SHALL select other panes belonging to the current Neovim pane's tab and capture recent text including non-visible scrollback up to a configurable line limit. It SHALL exclude the Neovim pane and panes in other tabs, including when its own pane is zoomed.

#### Scenario: Complete from scrollback in the same tab
- **WHEN** another pane in the same tab contains a matching word above its visible viewport within the capture limit
- **THEN** that word SHALL be eligible for completion

#### Scenario: Exclude other tabs and current pane
- **WHEN** matching text exists only in the current Neovim pane or a pane in another tab
- **THEN** default capture SHALL NOT offer that text

### Requirement: Layered capture and matching configuration
The plugin SHALL support plugin-wide defaults and per-source options, with per-source options taking precedence without modifying plugin defaults or another source configuration. Configurable settings SHALL include pane scope (tab, workspace, or explicit pane IDs), exclusion of the current pane, capture mode (recent unwrapped or visible), capture line limit, cache lifetime, request timeout, fuzzy backend, minimum and maximum candidate length, and maximum results. Defaults SHALL apply without requiring setup.

#### Scenario: Override one source
- **WHEN** plugin defaults capture tab scrollback and one source overrides capture to visible text from explicit pane IDs
- **THEN** that source SHALL use its overrides and other sources SHALL retain plugin defaults

#### Scenario: Configure plugin defaults
- **WHEN** the user configures workspace scope and a new line limit globally without per-source overrides
- **THEN** completion SHALL use those settings

### Requirement: Fuzzy candidate completion
The source SHALL return deduplicated fuzzy word candidates with score-aware ordering and bounded candidate lengths and result count. Terminal presentation escapes SHALL NOT appear in inserted text. Search command-line candidates SHALL escape search delimiters appropriately.

#### Scenario: Fuzzy match and deduplicate
- **WHEN** multiple selected panes contain the same word matching a non-contiguous typed pattern
- **THEN** the source SHALL offer the word once and rank results by fuzzy score

#### Scenario: Search completion
- **WHEN** a candidate containing a search delimiter is accepted in the search command line
- **THEN** its inserted representation SHALL escape that delimiter

### Requirement: Responsive capture and isolated results
Capture SHALL be asynchronous with bounded request duration and reusable cached results. Cache reuse SHALL respect connection identity, current pane and tab context, selected panes, and effective capture settings. Results from superseded completion requests SHALL NOT replace newer results. Expired capture SHALL refresh on subsequent completion.

#### Scenario: Change tab or source settings
- **WHEN** completion runs after the current pane changes tabs or the source changes its capture settings
- **THEN** candidates from an incompatible cached capture SHALL NOT be returned

#### Scenario: Older request finishes late
- **WHEN** an older capture completes after a newer completion request
- **THEN** it SHALL NOT replace results belonging to the newer request

### Requirement: Unavailable runtime and partial failures
Outside Herdr or without a compatible executable, the source SHALL be inactive. Missing context, malformed responses, timeouts, and disappeared panes SHALL resolve without blocking input or emitting repeated notifications. Failure of one pane SHALL NOT discard successful captures from other selected panes. Unknown tab context SHALL NOT broaden default scope.

#### Scenario: No Herdr runtime
- **WHEN** Neovim runs outside Herdr
- **THEN** the source SHALL provide no candidates and other completion sources SHALL continue normally

#### Scenario: Pane disappears during capture
- **WHEN** one selected pane closes while other pane reads succeed
- **THEN** completion SHALL use successful captures without an uncaught error

#### Scenario: Tab cannot be resolved
- **WHEN** the current pane's tab cannot be established under default settings
- **THEN** the source SHALL return no candidates rather than reading other tabs
