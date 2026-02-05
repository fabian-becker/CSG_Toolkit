@tool
extends Node
class_name CsgShortcutManager

# Provides global key handling for quick CSG creation & operation switching (Layers 1 & 2)
# Delegates actual creation to the sidebar instance to reuse UndoRedo + material logic.

var sidebar: CSGSideToolkitBar
var config: CsgTkConfig

# Mapping shape keycode -> factory id (string used for log / optional future use)
var _shape_key_map: Dictionary = {
	KEY_B: CSGBox3D,
	KEY_S: CSGSphere3D,
	KEY_C: CSGCylinder3D,
	KEY_T: CSGTorus3D,
	KEY_M: CSGMesh3D,
	KEY_P: CSGPolygon3D,
}

# Layer 2 operation selection numbers
var _op_number_map: Dictionary = {
	KEY_1: 0, # Union
	KEY_2: 1, # Intersection
	KEY_3: 2, # Subtraction
}

# Optional cycle order
var _op_cycle: Array = [0,1,2]
var _cycle_index := 0

func _enter_tree():
	set_process_unhandled_key_input(true)

func _unhandled_key_input(event: InputEvent):
	if not event is InputEventKey: return
	var ev := event as InputEventKey
	if not ev.pressed or ev.echo: return
	if config == null:
		config = get_tree().root.get_node_or_null(CsgToolkit.AUTOLOAD_NAME) as CsgTkConfig
	if sidebar == null:
		# Try to find existing sidebar if not explicitly set
		var candidates = get_tree().get_nodes_in_group("CSGSideToolkit")
		if candidates.size() > 0:
			sidebar = candidates[0]
	# Prevent interfering with text input fields
	var focus_owner = get_viewport().gui_get_focus_owner()
	if focus_owner and (focus_owner is LineEdit or focus_owner is TextEdit):
		return
	
	# Operation & shape shortcuts only trigger when primary action key is held (secondary key reserved for behavior inversion in creation)
	if Input.is_key_pressed(config.action_key):
		if ev.physical_keycode in _op_number_map:
			var op_val = _op_number_map[ev.physical_keycode]
			sidebar.set_operation(op_val)
			_print_feedback("Op -> %s" % _op_label(op_val))
			return
		# Cycle operation with backtick (`) or TAB
		if ev.physical_keycode in [KEY_APOSTROPHE, KEY_QUOTELEFT, KEY_TAB]:
			_cycle_index = (_cycle_index + 1) % _op_cycle.size()
			var cyc_op = _op_cycle[_cycle_index]
			sidebar.set_operation(cyc_op)
			_print_feedback("Op Cycle -> %s" % _op_label(cyc_op))
			return
		# Direct shape create (Layer 1)
		if ev.physical_keycode in _shape_key_map:
			_create_shape(_shape_key_map[ev.physical_keycode])
			return

func _create_shape(type_ref: Variant):
	if sidebar == null:
		_print_feedback("No sidebar found for creation")
		return
	# Delegates to sidebar logic (handles operation, insertion mode, UndoRedo, materials)
	sidebar.create_csg(type_ref)
	_print_feedback("Create %s (%s)" % [type_ref, _op_label(sidebar.operation)])

func _op_label(op: int) -> String:
	match op:
		0: return "Union"
		1: return "Intersect"
		2: return "Subtract"
		_: return str(op)

func _print_feedback(msg: String):
	print("CSG Toolkit: %s" % msg)
