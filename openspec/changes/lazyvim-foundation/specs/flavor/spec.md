## ADDED Requirements

### Requirement: Global flavor setting

The configuration SHALL support a top-level `flavor` key with the values `"koala"` and `"lazyvim"`, defaulting to `"koala"`. The flavor SHALL be a single global switch with no per-area overrides. The flavor SHALL choose between KoalaVim's and LazyVim's behavior in every area that other capabilities declare as flavor-dependent.

#### Scenario: Default flavor
- **WHEN** no configuration layer sets `flavor`
- **THEN** the effective flavor SHALL be `"koala"`

#### Scenario: Repository config selects flavor
- **WHEN** the user config sets `"flavor": "koala"` and a repository `.kvim.conf` sets `"flavor": "lazyvim"`
- **THEN** the effective flavor SHALL be `"lazyvim"`, following the three-layer merge

#### Scenario: Invalid flavor value
- **WHEN** a configuration layer sets `flavor` to an unknown value
- **THEN** the effective flavor SHALL be `"koala"` and a health warning SHALL be reported

### Requirement: Flavor available during spec resolution

The effective flavor SHALL be resolvable before lazy.nvim resolves plugin specs, so that spec fields (`enabled`, `cond`, `opts`, `keys`) and LazyVim globals (`vim.g.lazyvim_*`) can depend on it. A helper module SHALL expose the current flavor and a way to pick a value per flavor.

#### Scenario: Spec depends on flavor
- **WHEN** a KoalaVim plugin spec sets `enabled` based on the flavor helper
- **THEN** the plugin SHALL be enabled or disabled according to the effective flavor at startup

#### Scenario: Flavor change requires restart
- **WHEN** the user changes `flavor` in a config file while the editor is running
- **THEN** the running editor SHALL keep its startup flavor until restarted
