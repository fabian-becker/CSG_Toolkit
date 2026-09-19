@tool
class_name CsgTkConfig
extends RefCounted

## Plugin configuration using the official Godot mechanism: EditorSettings.
## Settings live under the "csg_toolkit/" namespace, show up in
## Editor -> Editor Settings (with enum hints and a working Revert button via
## set_initial_value), and are saved automatically by the editor. The legacy
## csg_toolkit_config.cfg is migrated once and then removed.

signal config_changed()

# EditorSettings keys (slash-delimited, snake_case per Godot convention).
const SETTING_DEFAULT_BEHAVIOR = "csg_toolkit/default_behavior"
const SETTING_ACTION_KEY = "csg_toolkit/action_key"
const SETTING_SECONDARY_ACTION_KEY = "csg_toolkit/secondary_action_key"
const SETTING_AUTO_HIDE = "csg_toolkit/auto_hide"

const LEGACY_CONFIG_PATH = "res://addons/csg_toolkit/csg_toolkit_config.cfg"
const LEGACY_SECTION = "CSG_TOOLKIT"

enum CSGBehavior { SIBLING, CHILD }

static var _instance: CsgTkConfig


## Lazily-created singleton. Lives for the editor session; a plugin (re)load
## reuses it, so EditorSettings registration happens only once.
## Order matters: migration runs BEFORE registration so that "setting already
## exists" still means "the user saved a value through EditorSettings" --
## registration itself creates every setting with its default.
static func instance() -> CsgTkConfig:
	if _instance == null:
		_instance = CsgTkConfig.new()
		_instance._migrate_legacy_config()
		_instance._register_settings()
	return _instance


# -- Settings-backed properties ------------------------------------------------------

var default_behavior: CSGBehavior:
	get: return get_setting(SETTING_DEFAULT_BEHAVIOR, CSGBehavior.SIBLING)
	set(value): set_setting(SETTING_DEFAULT_BEHAVIOR, value)

var action_key: Key:
	get: return get_setting(SETTING_ACTION_KEY, KEY_SHIFT)
	set(value): set_setting(SETTING_ACTION_KEY, value)

var secondary_action_key: Key:
	get: return get_setting(SETTING_SECONDARY_ACTION_KEY, KEY_ALT)
	set(value): set_setting(SETTING_SECONDARY_ACTION_KEY, value)

var auto_hide: bool:
	get: return get_setting(SETTING_AUTO_HIDE, true)
	set(value): set_setting(SETTING_AUTO_HIDE, value)


## Human-readable label for a configured key (used by the config window).
func key_label(key: Key) -> String:
	return OS.get_keycode_string(key)


## Explicit save hook for API compatibility. EditorSettings persists itself
## automatically on every change, so this only emits the change signal.
func save_config():
	config_changed.emit()


# -- EditorSettings plumbing ---------------------------------------------------------

## Registers the settings so they appear in Editor -> Editor Settings with
## proper type/hint metadata and a Revert-to-default button.
## NOTE: add_property_info() and set_initial_value() both REQUIRE the setting
## to already exist (Godot errors with "!props.has(pinfo.name)" otherwise), so
## every setting is created with its default first -- never overwriting values
## the user already saved.
func _register_settings():
	var settings := EditorInterface.get_editor_settings()
	_register_setting(settings, SETTING_DEFAULT_BEHAVIOR, CSGBehavior.SIBLING, {
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Sibling,Child",
	})
	_register_setting(settings, SETTING_ACTION_KEY, KEY_SHIFT, {})
	_register_setting(settings, SETTING_SECONDARY_ACTION_KEY, KEY_ALT, {})
	_register_setting(settings, SETTING_AUTO_HIDE, true, {})


func _register_setting(settings: EditorSettings, setting_name: String, default: Variant, extra_info: Dictionary):
	if not settings.has_setting(setting_name):
		settings.set_setting(setting_name, default)
	var info := {
		"name": setting_name,
		"type": typeof(default),
	}
	info.merge(extra_info)
	settings.set_initial_value(setting_name, default, false)
	settings.add_property_info(info)


func get_setting(name: String, default: Variant) -> Variant:
	var settings := EditorInterface.get_editor_settings()
	if settings.has_setting(name):
		return settings.get_setting(name)
	return default


func set_setting(name: String, value: Variant):
	EditorInterface.get_editor_settings().set_setting(name, value)
	config_changed.emit()


## One-time migration from the old custom ConfigFile implementation.
func _migrate_legacy_config():
	if not FileAccess.file_exists(LEGACY_CONFIG_PATH):
		return
	var legacy = ConfigFile.new()
	if legacy.load(LEGACY_CONFIG_PATH) != OK:
		print("CsgToolkit: Could not read legacy config, leaving %s in place." % LEGACY_CONFIG_PATH)
		return
	var settings := EditorInterface.get_editor_settings()
	# Never overwrite settings the user already changed through EditorSettings.
	if not settings.has_setting(SETTING_DEFAULT_BEHAVIOR):
		set_setting(SETTING_DEFAULT_BEHAVIOR, int(legacy.get_value(LEGACY_SECTION, "DEFAULT_BEHAVIOR", CSGBehavior.SIBLING)))
	if not settings.has_setting(SETTING_ACTION_KEY):
		set_setting(SETTING_ACTION_KEY, int(legacy.get_value(LEGACY_SECTION, "ACTION_KEY", KEY_SHIFT)))
	if not settings.has_setting(SETTING_SECONDARY_ACTION_KEY):
		set_setting(SETTING_SECONDARY_ACTION_KEY, int(legacy.get_value(LEGACY_SECTION, "SECONDARY_ACTION_KEY", KEY_ALT)))
	if not settings.has_setting(SETTING_AUTO_HIDE):
		set_setting(SETTING_AUTO_HIDE, bool(legacy.get_value(LEGACY_SECTION, "AUTO_HIDE", true)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(LEGACY_CONFIG_PATH))
	print("CsgToolkit: Migrated legacy config into Editor Settings.")
