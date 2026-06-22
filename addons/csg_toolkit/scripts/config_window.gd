@tool
extends Window

signal key_press(key: InputEventKey)

@onready var config: CsgTkConfig:
	get:
		return get_tree().root.get_node(CsgToolkit.AUTOLOAD_NAME) as CsgTkConfig

@onready var default_behavior_option: OptionButton = get_node(
	"MarginContainer/VBoxContainer/HBoxContainer/OptionButton"
)
@onready
var action_key_button: Button = get_node("MarginContainer/VBoxContainer/HBoxContainer2/Button")
@onready
var behvaior_toogle_button: Button = get_node("MarginContainer/VBoxContainer/HBoxContainer4/Button")
@onready var auto_hide_switch: CheckBox = get_node(
	"MarginContainer/VBoxContainer/HBoxContainer3/CheckButton"
)


func _ready() -> void:
	default_behavior_option.select(config.default_behavior)
	action_key_button.text = OS.get_keycode_string(config.action_key)
	behvaior_toogle_button.text = OS.get_keycode_string(config.secondary_action_key)
	auto_hide_switch.button_pressed = config.auto_hide


func _on_option_button_item_selected(index: int) -> void:
	match index:
		0:
			config.default_behavior = CsgTkConfig.CSGBehavior.SIBLING
		1:
			config.default_behavior = CsgTkConfig.CSGBehavior.CHILD


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed:
			key_press.emit(event)


func _on_save_pressed() -> void:
	config.save_config()
	hide()


func _on_button_pressed() -> void:
	var key_event: InputEventKey = await key_press
	config.action_key = key_event.keycode
	action_key_button.text = key_event.as_text_key_label()


func _on_second_button_pressed() -> void:
	var key_event: InputEventKey = await key_press
	config.secondary_action_key = key_event.keycode
	behvaior_toogle_button.text = key_event.as_text_key_label()


func _on_check_box_toggled(toggled_on: bool) -> void:
	config.auto_hide = toggled_on
