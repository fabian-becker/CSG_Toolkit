# CSG Toolkit Settings

Since **1.8.0**, the CSG Toolkit uses Godot's built-in **Editor Settings** system. Settings are per-user (shared across all your projects), never touch `project.godot`, and never ship in exported games.

## Accessing Settings

Settings can be accessed in two ways:

1. **Through the CSG Toolkit config window** (recommended)
   - Click the config button at the bottom of the CSG Toolkit sidebar
   - Rebind keys with a single click-then-press (click again to cancel capture)
   - Values apply instantly; **Save** closes and confirms

2. **Directly in Editor Settings** (for advanced users)
   - Go to **Editor → Editor Settings**
   - Look for the **CsgToolkit** section

## Available Settings

| Setting | Type | Default | Description |
| ------- | ---- | ------- | ----------- |
| `csg_toolkit/default_behavior` | Enum | Sibling | Default insertion behavior (Sibling or Child) when creating CSG nodes |
| `csg_toolkit/action_key` | Key | Shift | Primary action key: hold to add as child + trigger shortcuts |
| `csg_toolkit/secondary_action_key` | Key | Alt | Secondary key: inverts the primary insertion behavior |
| `csg_toolkit/auto_hide` | Boolean | true | Auto-hide the sidebar when no CSG nodes are selected |

Key bindings are stored as **physical keycodes**, so they work correctly on non-QWERTY layouts.

## Editor Session State

Per-project editor state (last selected CSG operation and picked material) is stored via `EditorSettings` project metadata. It survives editor restarts but is intentionally not version-controlled and does not affect exported games.

## Migration from Older Versions

- **≤ 1.6.x (`csg_toolkit_config.cfg`):** the plugin migrates your old values once on first load and deletes the legacy file automatically.
- **1.7.x (ProjectSettings):** settings moved to the user-level Editor Settings; re-configure once if you changed the defaults. The old `addons/csg_toolkit/*` ProjectSettings entries are no longer read and can be removed manually.

## Notes

- The plugin adds **no autoload** and mutates **no project files** — enabling/disabling it leaves `project.godot` untouched.
- Settings persist automatically; there is no explicit save step needed for Editor Settings (the config window's Save button just confirms the values).
