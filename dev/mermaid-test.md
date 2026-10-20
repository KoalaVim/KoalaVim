# Mermaid viewer test

Put the cursor inside a block and press `<leader>um`.

## Flowchart

```mermaid
flowchart TD
    A[Open markdown] --> B{Cursor in mermaid block?}
    B -->|Yes| C[Render with mmdr]
    B -->|No| D[Show error]
    C --> E[Display in float]
    E --> F{Source changed?}
    F -->|Yes| C
    F -->|No| G[Done]
```

## Sequence

```mermaid
sequenceDiagram
    participant U as User
    participant N as Neovim
    participant M as mmdr
    U->>N: :MermaidToggle
    N->>M: render source
    M-->>N: PNG
    N-->>U: kitty graphics float
    U->>N: + / - / hjkl
    N->>M: re-render at zoom
```

## State

```mermaid
stateDiagram-v2
    [*] --> Closed
    Closed --> Rendering: MermaidView
    Rendering --> Open: PNG ready
    Open --> Rendering: zoom / edit
    Open --> Closed: q / Esc
```

## Class

```mermaid
classDiagram
    class Viewer {
        +float win
        +number zoom
        +open()
        +close()
        +render()
    }
    class Renderer {
        +string mmdr_path
        +render(source) PNG
    }
    Viewer --> Renderer
```

## Pie

```mermaid
pie title Plugin load events
    "ft" : 45
    "cmd" : 30
    "keys" : 25
```

## Not mermaid (viewer should not pick this up)

```lua
print('hello')
```

## Broken diagram (error handling)

```mermaid
flowchart TD
    A -->
    --> B
```
