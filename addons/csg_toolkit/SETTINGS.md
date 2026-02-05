# CSG Toolkit Settings

The CSG Toolkit now uses Godot's built-in **ProjectSettings** system instead of a custom configuration file.

## Accessing Settings

Settings can be accessed in two ways:

1. **Through the CSG Toolkit config window** (recommended for users)
   - Click the config button in the CSG Toolkit sidebar
   - Modify settings using the UI
   - Click "Save" to persist changes

2. **Directly in Project Settings** (for advanced users)
   - Go to Project → Project Settings
   - Navigate to the "Addons" section
   - Look for `addons/csg_toolkit/*` settings

## Available Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `addons/csg_toolkit/default_behavior` | Enum | Sibling | Default insertion behavior (Sibling or Child) |
| `addons/csg_toolkit/action_key` | Key | Shift | Primary action key for shortcuts |
| `addons/csg_toolkit/secondary_action_key` | Key | Alt | Secondary action key for behavior inversion |
| `addons/csg_toolkit/auto_hide` | Boolean | true | Auto-hide sidebar when no CSG nodes selected |

## Migration from Old Config

If you were using an older version with `csg_toolkit_config.cfg`:
- The old config file is no longer used
- Settings are now stored in `project.godot`
- Settings will be initialized with defaults on first run
- You'll need to reconfigure your preferences if migrating

## Advantages of ProjectSettings

- Settings are version-controlled with your project
- Visible and editable in Project Settings editor
- Better integration with Godot's editor
- No separate config file to manage
- Settings persist per-project automatically
