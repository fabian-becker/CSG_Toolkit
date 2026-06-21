@tool
class_name CSGSideToolkitBar extends Control

var operation: CSGShape3D.Operation = CSGShape3D.OPERATION_UNION
var selected_material: BaseMaterial3D
var selected_shader: ShaderMaterial

@onready var config: CsgTkConfig:
	get:
		return get_tree().root.get_node_or_null(CsgToolkit.AUTOLOAD_NAME) as CsgTkConfig

@onready var picker_button: Button = $ScrollContainer/HBoxContainer/Material/MaterialPicker


func _enter_tree() -> void:
	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)


func _exit_tree() -> void:
	EditorInterface.get_selection().selection_changed.disconnect(_on_selection_changed)


func _on_selection_changed() -> void:
	if not config.auto_hide:
		return
	var selection: Array[Node] = EditorInterface.get_selection().get_selected_nodes()
	if selection.any(func(node): return node is CSGShape3D):
		show()
	else:
		hide()


func _ready() -> void:
	picker_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Connect material picker button if not connected via scene
	if not picker_button.pressed.is_connected(_on_material_picker_pressed):
		picker_button.pressed.connect(_on_material_picker_pressed)
	set_process_unhandled_key_input(true)


func _unhandled_key_input(event: InputEvent) -> void:
	# Shortcut: action_key + 1/2/3 to set operation (Union / Intersection / Subtraction)
	if not (event is InputEventKey):
		return
	var ev: InputEventKey = event as InputEventKey
	if ev.pressed and not ev.echo:
		# Ensure action key is held (config.action_key)
		if Input.is_key_pressed(config.action_key):
			match ev.physical_keycode:
				KEY_1, KEY_KP_1:
					set_operation(0)
					_accept_shortcut_feedback("Union")
				KEY_2, KEY_KP_2:
					set_operation(1)
					_accept_shortcut_feedback("Intersection")
				KEY_3, KEY_KP_3:
					set_operation(2)
					_accept_shortcut_feedback("Subtraction")


func _accept_shortcut_feedback(label: String) -> void:
	# Bypassing the GDScriptNativeClass assignment error.
	# EditorInterface is globally available if needed later.
	print("CSG Operation shortcut activated: %s" % label)


func set_operation(val: int) -> void:
	match val:
		0:
			operation = CSGShape3D.OPERATION_UNION
		1:
			operation = CSGShape3D.OPERATION_INTERSECTION
		2:
			operation = CSGShape3D.OPERATION_SUBTRACTION
		_:
			operation = CSGShape3D.OPERATION_UNION
	print("CSG operation set to index: %d" % val)


func _on_box_pressed() -> void:
	create_csg(CSGBox3D)


func _on_cylinder_pressed() -> void:
	create_csg(CSGCylinder3D)


func _on_mesh_pressed() -> void:
	create_csg(CSGMesh3D)


func _on_polygon_pressed() -> void:
	create_csg(CSGPolygon3D)


func _on_sphere_pressed() -> void:
	create_csg(CSGSphere3D)


func _on_torus_pressed() -> void:
	create_csg(CSGTorus3D)


# Operation Toggle (accept optional arg for signal variations)
func _on_operation_pressed(val: int = 0) -> void:
	set_operation(val)


func _on_config_pressed() -> void:
	const CONFIG_VIEW_SCENE: PackedScene = preload(
		"res://addons/csg_toolkit/scenes/config_window.tscn"
	)
	var config_view: Window = CONFIG_VIEW_SCENE.instantiate()
	config_view.close_requested.connect(
		func():
			get_tree().root.remove_child(config_view)
			config_view.queue_free()
	)
	get_tree().root.add_child(config_view)


func _request_material() -> void:
	var dialog: EditorFileDialog = EditorFileDialog.new()
	dialog.title = "Select Material"
	dialog.display_mode = EditorFileDialog.DISPLAY_LIST
	dialog.filters = ["*.tres, *.material, *.res"]
	dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	dialog.position = ((EditorInterface.get_base_control().size / 2) as Vector2i) - dialog.size
	dialog.close_requested.connect(
		func():
			get_tree().root.remove_child(dialog)
			dialog.queue_free()
	)
	get_tree().root.add_child(dialog)
	dialog.show()
	var res_path = await dialog.file_selected
	var res = ResourceLoader.load(res_path)
	if res == null:
		return
	if res is BaseMaterial3D:
		update_material(res)
	elif res is ShaderMaterial:
		update_shader(res)
	else:
		return
	var previewer: EditorResourcePreview = EditorInterface.get_resource_previewer()
	previewer.queue_edited_resource_preview(res, self, "_update_picker_icon", null)


func _update_picker_icon(
	_path: String, preview: Texture2D, _thumbnail: Texture2D, _userdata: Variant
) -> void:
	if preview:
		picker_button.icon = preview


func update_material(material: BaseMaterial3D) -> void:
	selected_material = material
	selected_shader = null
	print("CSG material updated: %s" % material.resource_path)


func update_shader(shader: ShaderMaterial) -> void:
	selected_material = null
	selected_shader = shader
	print("CSG shader updated: %s" % shader.resource_path)


func create_csg(type: Variant) -> void:
	print("Creating new CSG node of type: %s" % type)
	var selection: EditorSelection = EditorInterface.get_selection()
	var selected_nodes: Array[Node] = selection.get_selected_nodes()
	
	if selected_nodes.is_empty() or not (selected_nodes[0] is CSGShape3D):
		push_warning("Select a CSGShape3D to add a new CSG node.")
		return
		
	var selected_node: CSGShape3D = selected_nodes[0]
	var csg: CSGShape3D
	
	match type:
		CSGBox3D:
			csg = CSGBox3D.new()
		CSGCylinder3D:
			csg = CSGCylinder3D.new()
		CSGSphere3D:
			csg = CSGSphere3D.new()
		CSGMesh3D:
			csg = CSGMesh3D.new()
		CSGPolygon3D:
			csg = CSGPolygon3D.new()
		CSGTorus3D:
			csg = CSGTorus3D.new()

	csg.operation = operation
	if selected_material:
		csg.material = selected_material
	elif selected_shader:
		csg.material = selected_shader

	if selected_node.get_owner() == null:
		return

	var parent: Node
	var add_as_child: bool = false

	# Behavior inversion uses secondary_action_key (e.g., Alt)
	var invert: bool = Input.is_key_pressed(config.secondary_action_key)
	if config.default_behavior == CsgTkConfig.CSGBehavior.SIBLING:
		add_as_child = invert
	else:
		add_as_child = not invert

	parent = selected_node if add_as_child else selected_node.get_parent()
	if parent == null:
		return

	# Try undo manager path if plugin provided one
	if CsgToolkit.undo_manager:
		var insert_index: int = parent.get_child_count()
		CsgToolkit.undo_manager.create_action("Add %s" % csg.get_class())
		# DO methods
		CsgToolkit.undo_manager.add_do_method(
			self,
			"_undoable_add_csg",
			parent,
			csg,
			selected_node.get_owner(),
			selected_node.global_position,
			insert_index
		)
		CsgToolkit.undo_manager.add_do_method(self, "_select_created_csg", csg)
		# UNDO methods
		CsgToolkit.undo_manager.add_undo_method(self, "_undoable_remove_csg", parent, csg)
		CsgToolkit.undo_manager.add_undo_method(self, "_clear_selection_if", csg)
		CsgToolkit.undo_manager.commit_action()
	else:
		parent.add_child(csg, true)
		csg.owner = selected_node.get_owner()
		csg.global_position = selected_node.global_position
		call_deferred("_select_created_csg", csg)


func _deferred_select(csg: Node) -> void:
	call_deferred("_select_created_csg", csg)


func _undoable_add_csg(
	parent: Node, csg: CSGShape3D, owner_ref: Node, global_pos: Vector3, insert_index: int
):
	if csg.get_parent() != parent:
		parent.add_child(csg, true)
		if insert_index >= 0 and insert_index < parent.get_child_count():
			parent.move_child(csg, insert_index)
	csg.owner = owner_ref
	csg.global_position = global_pos


func _undoable_remove_csg(parent: Node, csg: CSGShape3D) -> void:
	if csg.get_parent() == parent:
		parent.remove_child(csg)
	# Intentionally do NOT free node so redo can re-add it.
	# If you need memory, implement a recreate pattern instead.


func _clear_selection_if(csg: Node) -> void:
	var selection: EditorSelection = EditorInterface.get_selection()
	if selection:
		var nodes: Array = selection.get_selected_nodes()
		if csg in nodes:
			selection.remove_node(csg)


func _select_created_csg(csg: Node) -> void:
	var selection: EditorSelection = EditorInterface.get_selection()
	selection.clear()
	selection.add_node(csg)


func _add_as_child(selected_node: CSGShape3D, csg: CSGShape3D) -> void:
	selected_node.add_child(csg, true)
	csg.owner = selected_node.get_owner()
	csg.global_position = selected_node.global_position


func _add_as_sibling(selected_node: CSGShape3D, csg: CSGShape3D) -> void:
	selected_node.get_parent().add_child(csg, true)
	csg.owner = selected_node.get_owner()
	csg.global_position = selected_node.global_position


func _on_material_picker_pressed() -> void:
	_request_material()
