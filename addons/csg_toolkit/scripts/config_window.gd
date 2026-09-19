@tool
extends Window

## Configuration window. Edits the plugin-owned CsgTkConfig singleton and
## refreshes its own widgets whenever the config is saved elsewhere.

@onready var config: CsgTkConfig = CsgTkConfig.instance()

@onready var default_behavior_option: OptionButton = $MarginContainer/VBoxContainer/HBoxContainer/OptionButton
@onready var action_key_button: Button = $MarginContainer/VBoxContainer/HBoxContainer2/Button
@onready var behavior_toggle_button: Button = $MarginContainer/VBoxContainer/HBoxContainer4/Button
@onready var auto_hide_switch: CheckBox = $MarginContainer/VBoxContainer/HBoxContainer3/CheckButton

signal key_press(key: InputEventKey)

# Guard so a second button press (or a closed window) can't stack up awaits.
var _awaiting_key_for: int = -1 # -1 none, 0 primary, 1 secondary

func _ready():
	config.config_changed.connect(_refresh_widgets)
	_refresh_widgets()

func _exit_tree():
	if config and config.config_changed.is_connected(_refresh_widgets):
		config.config_changed.disconnect(_refresh_widgets)
	# Cancel any pending key-capture awaits so they don't linger.
	_awaiting_key_for = -1

func _refresh_widgets():
	default_behavior_option.select(config.default_behavior)
	action_key_button.text = config.key_label(config.action_key)
	behavior_toggle_button.text = config.key_label(config.secondary_action_key)
	auto_hide_switch.button_pressed = config.auto_hide

func _on_option_button_item_selected(index):
	match index:
		0: config.default_behavior = CsgTkConfig.CSGBehavior.SIBLING
		1: config.default_behavior = CsgTkConfig.CSGBehavior.CHILD

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed:
			key_press.emit(event)

## Values now apply instantly through EditorSettings (auto-persisted by the
## editor). Kept for scene-wiring compatibility with the Save button.
func _on_save_pressed():
	config.save_config()

func _on_button_pressed():
	_capture_key(0, action_key_button, func (k: Key): config.action_key = k)

func _on_second_button_pressed():
	_capture_key(1, behavior_toggle_button, func (k: Key): config.secondary_action_key = k)

## Waits for exactly one key press and applies it to the given target.
## Re-clicking the same button cancels capture instead of stacking awaits,
## and only one capture can be active at a time.
func _capture_key(target: int, button: Button, apply_key: Callable):
	if _awaiting_key_for == target:
		# Second click cancels the pending capture.
		_awaiting_key_for = -1
		button.text = config.key_label(config.action_key if target == 0 else config.secondary_action_key)
		return
	_awaiting_key_for = target
	button.text = "..."
	var key_event: InputEventKey = await key_press
	# Window may have been freed while awaiting.
	if not is_instance_valid(button):
		return
	_awaiting_key_for = -1
	# Store the PHYSICAL keycode so shortcut handlers comparing
	# physical_keycode match regardless of the OS keyboard layout.
	var key := key_event.physical_keycode
	if key == KEY_NONE:
		return
	apply_key.call(key)
	button.text = config.key_label(key)

func _on_check_box_toggled(toggled_on):
	config.auto_hide = toggled_on
