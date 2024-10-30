@tool
class_name CSGSpreader3D extends CSGCombiner3D

const SPREADER_NODE_META = "SPREADER_NODE_META"

var _template_node_path: NodePath
@export var template_node_path: NodePath:
	get: return _template_node_path
	set(value):
		_template_node_path = value
		spread_template()

var _spread_area_3d: Shape3D = null
@export var spread_area_3d: Shape3D = null:
	get: return _spread_area_3d
	set(value):
		_spread_area_3d = value
		spread_template()

var _max_count: int = 10
@export var max_count: int = 10:
	get: return _max_count
	set(value):
		_max_count = value
		spread_template()

@export_group("Spread Options")
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

var _allow_rotation: bool = false
@export var allow_rotation: bool = false:
	get: return _allow_rotation
	set(value):
		_allow_rotation = value
		spread_template()

var _allow_scale: bool = false
@export var allow_scale: bool = false:
	get: return _allow_scale
	set(value):
		_allow_scale = value
		spread_template()

var _snap_distance = 0
@export var snap_distance = 0:
	get: return _snap_distance
	set(value):
		_snap_distance = value
		spread_template()

var rng: RandomNumberGenerator

func _ready():
	rng = RandomNumberGenerator.new()
	spread_template()

func clear_children():
	# Clear existing children except the template node
	for child in get_children(true):
		if child.has_meta(SPREADER_NODE_META):
			child.queue_free()

func get_random_position_in_area() -> Vector3:
	if spread_area_3d is SphereShape3D:
		# Sphere: Random point within the sphere's radius
		var radius = spread_area_3d.get_radius()
		var random_radius = rng.randf_range(0, radius)
		var random_direction = Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)).normalized()
		return random_direction * random_radius

	if spread_area_3d is BoxShape3D:
		# Box: Random point within the box's AABB (Axis-Aligned Bounding Box)
		var aabb = spread_area_3d.size
		var x = rng.randf_range(0, aabb.x)
		var y = rng.randf_range(0, aabb.y)
		var z = rng.randf_range(0, aabb.z)
		return Vector3(x, y, z)

	if spread_area_3d is CapsuleShape3D:
		# Capsule: Random point within the capsule's bounds
		var radius = spread_area_3d.get_radius()
		var height = spread_area_3d.get_height() / 2
		# Choose either hemisphere or cylindrical part
		if rng.randf() < 0.5:
			# Generate point in the cylinder
			var angle = rng.randf_range(0.0, TAU)
			var x = radius * cos(angle)
			var z = radius * sin(angle)
			var y = rng.randf_range(-height, height)
			return Vector3(x, y, z)
		else:
			# Generate point in one of the hemispheres
			var hemisphere_offset = Vector3(0, height, 0) if rng.randf() < 0.5 else Vector3(0, -height, 0)
			var random_radius = rng.randf_range(0, radius)
			var random_direction = Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)).normalized()
			return hemisphere_offset + random_direction * random_radius

	if spread_area_3d is CylinderShape3D:
		# Cylinder: Random point within the cylinder's bounds
		var radius = spread_area_3d.get_radius()
		var height = spread_area_3d.get_height() / 2
		var angle = rng.randf_range(0.0, TAU)
		var x = radius * cos(angle)
		var z = radius * sin(angle)
		var y = rng.randf_range(-height, height)
		return Vector3(x, y, z).normalized() * rng.randf_range(0, radius)

	if spread_area_3d is HeightMapShape3D:
		# HeightMap: Not fully supported, returning surface point for simplicity
		var width = spread_area_3d.map_width
		var depth = spread_area_3d.map_depth
		var get_hight = func(x,y): pass
		var x = rng.randi_range(0, width)
		var z = rng.randi_range(0, depth)
		var y = spread_area_3d.map_data[x * z]
		return Vector3(x, y, z)

	if spread_area_3d is WorldBoundaryShape3D:
		# WorldBoundary: Infinite boundary, return zero or random large value
		return Vector3.ZERO # This shape is usually infinite

	if spread_area_3d is ConvexPolygonShape3D or spread_area_3d is ConcavePolygonShape3D:
		# Convex/Concave Polygon: Complex geometry, approximate with bounding box
		var aabb = spread_area_3d.get_aabb()
		var x = rng.randf_range(aabb.position.x, aabb.position.x + aabb.size.x)
		var y = rng.randf_range(aabb.position.y, aabb.position.y + aabb.size.y)
		var z = rng.randf_range(aabb.position.z, aabb.position.z + aabb.size.z)
		return Vector3(x, y, z)
	
	print("Type of ", typeof(spread_area_3d), " is not supported")
	return Vector3.ZERO # Default case if no shape is recognized

func spread_template():
	clear_children()
	if not spread_area_3d:
		return

	var template_node = get_node_or_null(template_node_path)
	if not template_node:
		return

	if seed == 0:
		rng.randomize()
	else:
		rng.seed = seed

	# Spread the template node around the area
	for i in range(max_count):
		var instance = template_node.duplicate()
		instance.set_meta(SPREADER_NODE_META, true)
		
		# Position the instance
		var noise_value = rng.randf()
		if noise_value > noise_threshold:
			instance.transform.origin = get_random_position_in_area()
			if allow_rotation:
				instance.transform.basis = Basis().rotated(Vector3(0, 1, 0), rng.randf_range(0, 2 * PI))
			if allow_scale:
				instance.transform.basis = Basis().scaled(Vector3(rng.randf_range(0, 2),rng.randf_range(0, 2),rng.randf_range(0, 2)))
			add_child(instance)

func apply_template():
	if get_child_count() == 0:
		return
	seed = rng.seed;
	var stack = []
	stack.append_array(get_children())
	while stack.size() > 0:
		var node = stack.pop_back()
		node.set_owner(owner)
		stack.append_array(node.get_children())
