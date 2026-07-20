## Purpose

Git integration provides comprehensive version control from within the editor: inline hunk signs with staging/reset, side-by-side diff viewing, commit and push workflows, git log graph browsing, line blame, conflict resolution, and GitHub issue/PR management.

## Requirements

### Requirement: Hunk signs

The system SHALL display sign column markers for added, changed, and deleted lines relative to the git index. Hunk navigation, staging, resetting, and previewing SHALL be available at the hunk level.

#### Scenario: Stage a hunk
- **WHEN** the cursor is inside a modified hunk and the user triggers stage-hunk
- **THEN** only that hunk SHALL be staged in the git index, leaving other changes unstaged

#### Scenario: Navigate between hunks
- **WHEN** the user triggers next-hunk navigation
- **THEN** the cursor SHALL jump to the first line of the next modified hunk in the buffer

#### Scenario: Undo staged hunk
- **WHEN** the user triggers undo-stage on a previously staged hunk
- **THEN** the hunk SHALL be unstaged from the index and returned to the working tree

#### Scenario: Preview hunk
- **WHEN** the user triggers hunk preview
- **THEN** a popup SHALL show the diff for the hunk under the cursor

### Requirement: Inline word-level diff

The system SHALL support toggling word-level inline diff highlighting within a hunk, showing exactly which characters changed.

#### Scenario: Toggle inline diff
- **WHEN** the user toggles inline diff mode
- **THEN** modified hunks SHALL show character-level additions and deletions highlighted inline

### Requirement: Git status UI

The system SHALL provide a full git status interface for staging, committing, pushing, and pulling. The UI SHALL open in a floating window and support section toggling and navigation.

#### Scenario: Open git status
- **WHEN** the user triggers the git status command
- **THEN** a UI SHALL open showing staged, unstaged, and untracked files with the ability to stage/unstage individual files or hunks

### Requirement: Diff viewer

The system SHALL provide a side-by-side (or inline) diff viewer with a file explorer panel, file history browsing, and conflict resolution support. The viewer SHALL support staging and committing directly from the diff view.

#### Scenario: View current changes
- **WHEN** the user triggers the diff view command
- **THEN** a diff viewer SHALL open showing all modified files with side-by-side or inline diffs

#### Scenario: File history
- **WHEN** the user triggers file history on the current file
- **THEN** a chronological list of commits affecting that file SHALL appear, with each commit's diff viewable

#### Scenario: Visual selection history
- **WHEN** the user selects a range of lines in visual mode and triggers history
- **THEN** the git log SHALL be filtered to show only commits that modified the selected line range

#### Scenario: Conflict resolution
- **WHEN** the diff viewer encounters merge conflict markers
- **THEN** it SHALL present the conflicting versions with options to accept current, incoming, or both changes

#### Scenario: Stage from diff view
- **WHEN** the user triggers stage/unstage/reset within the diff viewer
- **THEN** the corresponding hunk or file SHALL be staged/unstaged/reset in the git index

### Requirement: Commit message interface

The system SHALL support composing git commits, including amend commits, from within the editor. The commit message editor SHALL integrate with the git workflow UI.

#### Scenario: Create commit
- **WHEN** the user triggers the commit command with staged changes
- **THEN** a commit message editor SHALL open, and confirming SHALL create the git commit

### Requirement: Line blame and commit popup

The system SHALL show the git commit responsible for the current line in both the status line (author + date) and in a detailed floating popup on demand.

#### Scenario: Status line blame
- **WHEN** the cursor is on a line in a git-tracked file
- **THEN** the status line SHALL display the author and relative date of the commit that last modified this line

#### Scenario: Commit popup
- **WHEN** the user triggers the commit popup command on a line
- **THEN** a floating popup SHALL show the full commit message and metadata for the commit that last modified this line

#### Scenario: Moved code detection
- **WHEN** blame is triggered with the `-C` option
- **THEN** the system SHALL detect code that was moved or copied from other files and attribute it to the original commit

### Requirement: Git log graph

The system SHALL provide a visual git log browser showing commit history as a graph with branch and merge visualization. Filtering, diff viewing from selected commits, and commit hash copying SHALL be supported.

#### Scenario: Browse log graph
- **WHEN** the user triggers the git log graph command
- **THEN** a visual graph of commit history SHALL appear with branch/merge lines

#### Scenario: View commit diff from graph
- **WHEN** the user selects a commit in the log graph
- **THEN** the diff viewer SHALL open showing the changes introduced by that commit

### Requirement: GitHub integration

The system SHALL support browsing, creating, commenting on, and reviewing GitHub issues and pull requests from within the editor. PR reviews SHALL support code comments, approvals, and merge operations.

#### Scenario: List issues
- **WHEN** the user triggers list-issues for the current repository
- **THEN** a picker SHALL show all open issues with title, number, and labels

#### Scenario: Create issue
- **WHEN** the user triggers create-issue
- **THEN** an editor buffer SHALL open for composing the issue title and body, and submitting SHALL create the issue on GitHub

#### Scenario: Review pull request
- **WHEN** the user opens a pull request for review
- **THEN** the PR's changed files SHALL be viewable in the diff viewer with the ability to add inline comments

#### Scenario: Merge pull request
- **WHEN** the user triggers merge on a reviewed PR
- **THEN** the PR SHALL be merged using the configured merge strategy (default: squash)

### Requirement: Cross-file hunk navigation

The system SHALL support navigating between git-dirty files in the project, jumping to the first hunk in each dirty file.

#### Scenario: Jump to next dirty file
- **WHEN** the user triggers next-dirty-file navigation
- **THEN** the editor SHALL open the next file with uncommitted changes and position the cursor at the first modified hunk
