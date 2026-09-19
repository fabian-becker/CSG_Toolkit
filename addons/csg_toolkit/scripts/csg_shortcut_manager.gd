@tool
extends Node
class_name CsgShortcutManager

## Single owner of all global key handling for quick CSG creation and
## operation switching. The sidebar no longer listens for keys itself; the
## manager delegates creation to the sidebar to reuse UndoRedo + material logic
## and marks every event handled so nothing leaks into the editor.

var sidebar: CSGSideToolkitBar
var config: CsgTkConfig

# Mapping shape keycode -> factory class (class reference used in logs).
var _shape_key_map: Dictionary = {
	KEY_B: CSGBox3D,
	KEY_S: CSGSphere3D,
	KEY_C: CSGCylinder3D,
	KEY_T: CSGTorus3D,
	KEY_M: CSGMesh3D,
	KEY_P: CSGPolygon3D,
}

# Operation selection numbers (values are CSGShape3D.Operation).
var _op_number_map: Dictionary = {
	KEY_1: CSGShape3D.OPERATION_UNION,
	KEY_2: CSGShape3D.OPERATION_INTERSECTION,
	KEY_3: CSGShape3D.OPERATION_SUBTRACTION,
}

# Optional cycle order (backtick / quote) -- TAB intentionally excluded because
# it collides with editor UI traversal while the action key is held.
var _op_cycle: Array = [
	CSGShape3D.OPERATION_UNION,
	CSGShape3D.OPERATION_INTERSECTION,
	CSGShape3D.OPERATION_SUBTRACTION,
]
var _cycle_index := 0

func _enter_tree():
	set_process_unhandled_key_input(true)

func _unhandled_key_input(event: InputEvent):
	if not event is InputEventKey: return
	var ev := event as InputEventKey
	if not ev.pressed or ev.echo: return
	if config == null:
		config = CsgTkConfig.instance()
	if sidebar == null:
		# Try to find existing sidebar if not explicitly set
		var candidates = get_tree().get_nodes_in_group("CSGSideToolkit")
		if candidates.size() > 0:
			sidebar = candidates[0]
	# Prevent interfering with text input fields
	var focus_owner = get_viewport().gui_get_focus_owner()
	if focus_owner and (focus_owner is LineEdit or focus_owner is TextEdit):
		return

	# Only trigger while the primary action key is held. The secondary key is
	# reserved for behavior inversion at creation time.
	if not Input.is_key_pressed(config.action_key):
		return

	if ev.physical_keycode in _op_number_map:
		var op_val = _op_number_map[ev.physical_keycode]
		sidebar.set_operation(op_val)
		_print_feedback("Op -> %s" % sidebar.get_operation_label())
		get_viewport().set_input_as_handled()
		return
	# Cycle operation with backtick (`) or apostrophe (')
	if ev.physical_keycode in [KEY_APOSTROPHE, KEY_QUOTELEFT]:
		_cycle_index = (_cycle_index + 1) % _op_cycle.size()
		var cyc_op = _op_cycle[_cycle_index]
		sidebar.set_operation(cyc_op)
		_print_feedback("Op Cycle -> %s" % sidebar.get_operation_label())
		get_viewport().set_input_as_handled()
		return
	# Direct shape create (Layer 1)
	if ev.physical_keycode in _shape_key_map:
		if sidebar == null:
			_print_feedback("No sidebar found for creation")
			return
		_create_shape(_shape_key_map[ev.physical_keycode])
		get_viewport().set_input_as_handled()

func _create_shape(type_ref: Variant):
	if sidebar == null:
		_print_feedback("No sidebar found for creation")
		return
	# Delegates to sidebar logic (handles operation, insertion mode, UndoRedo, materials)
	sidebar.create_csg(type_ref)
	_print_feedback("Create %s (%s)" % [type_ref, sidebar.get_operation_label()])

func _print_feedback(msg: String):
	print("CSG Toolkit: %s" % msg)
