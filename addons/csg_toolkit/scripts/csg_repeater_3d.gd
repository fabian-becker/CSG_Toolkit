@tool
class_name CSGRepeater3D extends CSGCombiner3D

const REPEATER_NODE_META = "REPEATED_NODE_META"

var _template_node_path: NodePath
@export var template_node_path: NodePath:
	get: return _template_node_path
	set(value):
		_template_node_path = value
		repeat_template()

var _template_node_scene: PackedScene
@export var template_node_scene: PackedScene:
	get: return _template_node_scene
	set(value):
		_template_node_scene = value
		repeat_template()

var _repeat: Vector3 = Vector3.ONE
@export var repeat := Vector3.ONE:
	get:
		return _repeat
	set(value):
		_repeat = value
		repeat_template()

var _spacing: Vector3 = Vector3.ZERO
@export var spacing := Vector3.ZERO:
	get:
		return _spacing
	set(value):
		_spacing = value
		repeat_template()

func _ready():
	repeat_template()

func _exit_tree():
	if not Engine.is_editor_hint(): return
	
func clear_children():
	# Clear existing children except the template node
	for child in get_children(true):
		if child.has_meta(REPEATER_NODE_META):
			child.queue_free() # free repeated ndoes

func repeat_template():
	clear_children()

	var template_node = get_node_or_null(template_node_path)
	if not template_node and (not template_node_scene or not template_node_scene.can_instantiate()):
		return
	if not template_node:
		template_node = template_node_scene.instantiate()
	
	# Clone and position the template node based on repeat and spacing
	for x in range(int(_repeat.x)):
		for y in range(int(_repeat.y)):
			for z in range(int(_repeat.z)):
				if x == 0 and y == 0 and z == 0: continue
				# Instance a new template node
				var instance = template_node.duplicate()
				instance.set_meta(REPEATER_NODE_META, true)
				# Position the instance
				var position = Vector3(
					x * (_spacing.x + template_node.transform.origin.x),
					y * (_spacing.y + template_node.transform.origin.y),
					z * (_spacing.z + template_node.transform.origin.z)
				)
				instance.transform.origin = position
				# Add the instance to the combiner
				add_child(instance)
	if template_node_scene:
		template_node.queue_free()

func apply_template():
	if get_child_count() == 0:
		return
	var stack = []
	stack.append_array(get_children())
	while stack.size() > 0:
		var node = stack.pop_back()
		node.set_owner(owner)
		stack.append_array(node.get_children())
