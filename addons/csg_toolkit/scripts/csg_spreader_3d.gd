@tool
class_name CSGSpreader3D extends CSGCombiner3D

const SPREADER_NODE_META = "SPREADER_NODE_META"

var _template_node_path: NodePath
@export var template_node_path: NodePath:
	get: return _template_node_path
	set(value):
		_template_node_path = value
		spread_template()

var _template_node_scene: PackedScene
@export var template_node_scene: PackedScene:
	get: return _template_node_scene
	set(value):
		_template_node_scene = value
		spread_template()

var _max_count: int = 10
@export var max_count: int = 10:
	get: return _max_count
	set(value):
		_max_count = value
		spread_template()

var _noise_threshold: float = 0.5
@export var noise_threshold: float = 0.5:
	get: return _noise_threshold
	set(value):
		_noise_threshold = value
		spread_template()

var _seed: int = 0
@export var seed: int = 0:
	get: return _seed
	set(value):
		_seed = value
		spread_template()

var _spread_area = Vector3(10, 10, 10)
## Box area around this node.
@export var spread_area: Vector3 = Vector3(10, 10, 10):
	get: return _spread_area
	set(value):
		_spread_area = value
		spread_template()

var _allow_rotation: bool = false
@export var allow_rotation: bool = false:
	get: return _allow_rotation
	set(value):
		_allow_rotation = value
		spread_template()

func _ready():
	spread_template()

func clear_children():
	# Clear existing children except the template node
	for child in get_children(true):
		if child.has_meta(SPREADER_NODE_META):
			child.queue_free()


func spread_template():
	clear_children()

	var template_node = get_node_or_null(template_node_path)
	if not template_node and (not template_node_scene or not template_node_scene.can_instantiate()):
		return
	if not template_node:
		template_node = template_node_scene.instantiate()

	var rng = RandomNumberGenerator.new()
	if seed == 0:
		rng.randomize()
	else:
		rng.seed = seed

	# Spread the template node around the area
	for i in range(max_count):
		var instance = template_node.duplicate()
		instance.set_meta(SPREADER_NODE_META, true)
		# Position the instance
		var position = Vector3(
			rng.randf_range(-spread_area.x / 2, spread_area.x / 2),
			rng.randf_range(-spread_area.y / 2, spread_area.y / 2),
			rng.randf_range(-spread_area.z / 2, spread_area.z / 2)
		)
		
		var noise_value = rng.randf()
		if noise_value > noise_threshold:
			instance.transform.origin = position
			if allow_rotation:
				instance.transform.basis = Basis().rotated(Vector3(0, 1, 0), rng.randf_range(0, 2 * PI))
			add_child(instance)
	# Free template node scene
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
