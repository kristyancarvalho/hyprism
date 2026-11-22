---
title: Writing documentation
description: "Author pages in docs/, link between them, and draw Mermaid diagrams that the website renders."
category: Project
order: 22
icon: pencil-line
---

The Markdown files in `docs/` are the only copy of the documentation. GitHub renders them directly, and the Astro website in `website/` loads the same files through a content collection, so a change here appears in both places.

## Front matter

Each page starts with YAML front matter that the website uses for navigation and metadata.

| Field | Purpose |
| --- | --- |
| `title` | Page heading and navigation label |
| `description` | Summary under the heading and in search results |
| `category` | Group in the documentation sidebar |
| `order` | Position in the sidebar; lower numbers come first |
| `icon` | Lucide icon name shown next to the page |

## Links and images

Link to other pages with relative Markdown paths such as `[CLI reference](cli.md)`. The website rewrites them to its own routes, and GitHub follows them as files. Images under `assets/screenshots/` and `assets/demo/` resolve on both.

## Diagrams

Write diagrams as fenced code blocks with the `mermaid` language. No HTML or components are needed. The website renders them in the browser with the bundled Mermaid library, follows the light and dark theme, and scrolls wide diagrams horizontally. If a diagram has a syntax error, the page still loads and shows the diagram source with a short notice.

Use a diagram when it explains a flow or relationship better than prose. These examples show the supported types.

### Flowchart

```mermaid
flowchart LR
    Login[Hyprland starts] --> Autostart[autostart.lua]
    Autostart --> Shell[start-shell]
    Autostart --> Wallpaper[wallpaper restore]
    Shell --> Quickshell[Quickshell shell.qml]
```

### Sequence diagram

```mermaid
sequenceDiagram
    participant User
    participant CLI as hyprism-shell
    participant Config as user.json
    participant Shell as Quickshell
    User->>CLI: widgets toggle weather
    CLI->>Config: atomic write
    Config-->>Shell: file change
    Shell->>Shell: hide or show the card
```

### State diagram

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Authenticating: Return
    Authenticating --> Unlocking: PAM success
    Authenticating --> Idle: PAM failure
    Unlocking --> [*]
```

### Class diagram

```mermaid
classDiagram
    class ShellButton {
        bool available
        bool keyboardFocusable
        clicked()
    }
    class MediaStrip {
        bool keyboardControls
    }
    MediaStrip *-- ShellButton : previous, toggle, next
```

### Entity relationship diagram

```mermaid
erDiagram
    USER_CONFIG ||--o{ WIDGET : enables
    USER_CONFIG ||--|| APPEARANCE : sets
    USER_CONFIG ||--o| WEATHER : locates
```
