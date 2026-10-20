## ADDED Requirements

### Requirement: Flavor-selected session backend

The session backend SHALL follow the flavor: possession for `koala`, persistence for `lazyvim`. Auto-save, per-directory sessions, auto-load, the session list, disable controls and component state hooks SHALL work through a common adapter in both flavors. Sessions saved under one backend SHALL NOT be visible to the other.

#### Scenario: LazyVim flavor auto-load
- **WHEN** the flavor is `lazyvim` and the editor starts in a directory with a persistence session
- **THEN** that session SHALL be restored automatically

#### Scenario: Component hooks under LazyVim flavor
- **WHEN** the flavor is `lazyvim` and a component registered a before-save hook
- **THEN** the hook SHALL run before persistence saves, and its data SHALL be restored to the component's after-load hook on the next load

#### Scenario: Backend isolation
- **WHEN** a session was saved with the `koala` flavor and the user restarts with the `lazyvim` flavor
- **THEN** the possession session SHALL NOT be loaded

## MODIFIED Requirements

### Requirement: Named sessions

With the `koala` flavor, the system SHALL support creating, loading, renaming and deleting named sessions independent of the working directory. Named sessions SHALL NOT be available with the `lazyvim` flavor.

#### Scenario: Save named session
- **WHEN** the flavor is `koala` and the user creates a named session called "feature-work"
- **THEN** the current state SHALL be saved under that name and retrievable later

#### Scenario: Load named session
- **WHEN** the flavor is `koala` and the user loads a named session
- **THEN** the editor state SHALL be restored to the saved session's state
