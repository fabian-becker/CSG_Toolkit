@tool
class_name CSGSpreader3D extends CSGCombiner3D

const SPREADER_NODE_META = "SPREADER_NODE_META"
const MAX_INSTANCES = 20000

var _dirty: bool = false
var _generation_in_progress := false
var _template_node_path: NodePath
@export var template_node_path: NodePath:
	get: return _template_node_path
	set(value):
		_template_node_path = value
		_mark_dirty()

var _spread_area_3d: Shape3D = null
@export var spread_area_3d: Shape3D = null:
	get: return _spread_area_3d
	set(value):
		_spread_area_3d = value
		_mark_dirty()

var _max_count: int = 10
@export var max_count: int = 10:
	get: return _max_count
	set(value):
		_max_count = clamp(value, 1, 100000)
		_mark_dirty()

@export_group("Spread Options")
var _noise_threshold: float = 0.5
@export var noise_threshold: float = 0.5:
	get: return _noise_threshold
	set(value):
		_noise_threshold = clamp(value, 0.0, 1.0)
		_mark_dirty()

var _seed: int = 0
@export var seed: int = 0:
	get: return _seed
	set(value):
		_seed = value
		_mark_dirty()

var _allow_rotation: bool = false
@export var allow_rotation: bool = false:
	get: return _allow_rotation
	set(value):
		_allow_rotation = value
		_mark_dirty()

var _allow_scale: bool = false
@export var allow_scale: bool = false:
	get: return _allow_scale
	set(value):
		_allow_scale = value
		_mark_dirty()

var _snap_distance = 0
@export var snap_distance = 0:
	get: return _snap_distance
	set(value):
		_snap_distance = value
		_mark_dirty()

@export_group("Collision Options")
var _avoid_overlaps: bool = false
@export var avoid_overlaps: bool = false:
	get: return _avoid_overlaps
	set(value):
		_avoid_overlaps = value
		_mark_dirty()

var _min_distance: float = 1.0
@export var min_distance: float = 1.0:
	get: return _min_distance
	set(value):
		_min_distance = max(0.0, value)
		_mark_dirty()

var _max_placement_attempts: int = 100
@export var max_placement_attempts: int = 100:
	get: return _max_placement_attempts
	set(value):
		_max_placement_attempts = clamp(value, 10, 1000)
		_mark_dirty()

@export var estimated_instances: int = 0

var rng: RandomNumberGenerator

func _ready():
	rng = RandomNumberGenerator.new()
	_mark_dirty()
	# Generate instances in-game on ready
	if not Engine.is_editor_hint():
		call_deferred("spread_template")

func _process(_delta):
	if not Engine.is_editor_hint(): return
	if _dirty and not _generation_in_progress:
		_dirty = false
		call_deferred("spread_template")

func _exit_tree():
	if not Engine.is_editor_hint():
		return
	clear_children()

func _mark_dirty():
	_dirty = true

func clear_children():
	var children_to_remove = []
	for child in get_children(true):
		if child.has_meta(SPREADER_NODE_META):
			children_to_remove.append(child)
	for child in children_to_remove:
		remove_child(child)
		child.queue_free()

func get_random_position_in_area() -> Vector3:
	if spread_area_3d is SphereShape3D:
		var radius = spread_area_3d.get_radius()
		var u = rng.randf()
		var v = rng.randf()
		var theta = u * TAU
		var phi = acos(2.0 * v - 1.0)
		var r = radius * pow(rng.randf(), 1.0/3.0)
		return Vector3(r * sin(phi) * cos(theta), r * sin(phi) * sin(theta), r * cos(phi))
	if spread_area_3d is BoxShape3D:
		var size = spread_area_3d.size
		return Vector3(
			rng.randf_range(-size.x * 0.5, size.x * 0.5),
			rng.randf_range(-size.y * 0.5, size.y * 0.5),
			rng.randf_range(-size.z * 0.5, size.z * 0.5)
		)
	if spread_area_3d is CapsuleShape3D:
		var radius = spread_area_3d.get_radius()
		var height = spread_area_3d.get_height() * 0.5
		if rng.randf() < noise_threshold:
			var angle = rng.randf() * TAU
			var r = radius * sqrt(rng.randf())
			return Vector3(r * cos(angle), rng.randf_range(-height, height), r * sin(angle))
		else:
			var hemisphere_y = height if rng.randf() < noise_threshold else -height
			var u = rng.randf()
			var v = rng.randf()
			var theta = u * TAU
			var phi = acos(1.0 - v)
			var r = radius * pow(rng.randf(), 1.0/3.0)
			return Vector3(
				r * sin(phi) * cos(theta),
				hemisphere_y + r * cos(phi) * (1 if hemisphere_y > 0 else -1),
				r * sin(phi) * sin(theta)
			)
	if spread_area_3d is CylinderShape3D:
		var radius = spread_area_3d.get_radius()
		var height = spread_area_3d.get_height() * 0.5
		var angle = rng.randf() * TAU
		var r = radius * sqrt(rng.randf())
		return Vector3(r * cos(angle), rng.randf_range(-height, height), r * sin(angle))
	if spread_area_3d is HeightMapShape3D:
		var width = spread_area_3d.map_width
		var depth = spread_area_3d.map_depth
		if width <= 0 or depth <= 0 or spread_area_3d.map_data.size() == 0:
			return Vector3.ZERO
		var x = rng.randi_range(0, width - 1)
		var z = rng.randi_range(0, depth - 1)
		var index = x + z * width
		if index < spread_area_3d.map_data.size():
			return Vector3(x, spread_area_3d.map_data[index], z)
		return Vector3.ZERO
	if spread_area_3d is WorldBoundaryShape3D:
		var bound = 100.0
		return Vector3(rng.randf_range(-bound, bound), 0, rng.randf_range(-bound, bound))
	if spread_area_3d is ConvexPolygonShape3D or spread_area_3d is ConcavePolygonShape3D:
		var pts = spread_area_3d.points if spread_area_3d.has_method("get_points") else []
		if pts.size() == 0:
			return Vector3.ZERO
		var min_point = pts[0]
		var max_point = pts[0]
		for p in pts:
			min_point = min_point.min(p)
			max_point = max_point.max(p)
		return Vector3(
			rng.randf_range(min_point.x, max_point.x),
			rng.randf_range(min_point.y, max_point.y),
			rng.randf_range(min_point.z, max_point.z)
		)
	push_warning("CSGSpreader3D: Shape type not supported")
	return Vector3.ZERO

func spread_template():
	if _generation_in_progress:
		return
	_generation_in_progress = true
	if not spread_area_3d:
		_generation_in_progress = false
		return
	clear_children()
	var template_node = get_node_or_null(template_node_path)
	if not template_node:
		_generation_in_progress = false
		return

	rng.seed = _seed
	var instances_created = 0
	var placed_positions = []
	var budget = min(_max_count, MAX_INSTANCES)
	if _max_count > MAX_INSTANCES:
		push_warning("CSGSpreader3D: max_count %s exceeds cap %s. Limiting." % [_max_count, MAX_INSTANCES])
	for i in range(budget):
		var noise_value = rng.randf()
		if noise_value <= _noise_threshold:
			continue
		var position_found = false
		var final_position = Vector3.ZERO
		var attempts = _max_placement_attempts if _avoid_overlaps else 1
		for attempt in range(attempts):
			var test_position = get_random_position_in_area()
			if not _avoid_overlaps:
				final_position = test_position
				position_found = true
				break
			var overlap = false
			for existing_pos in placed_positions:
				if test_position.distance_to(existing_pos) < _min_distance:
					overlap = true
					break
			if not overlap:
				final_position = test_position
				position_found = true
				break
		if not position_found:
			continue
		var instance = template_node.duplicate()
		if instance == null:
			continue
		instance.set_meta(SPREADER_NODE_META, true)
		instance.transform.origin = final_position
		placed_positions.append(final_position)
		if _allow_rotation:
			var rotation_y = rng.randf_range(0, TAU)
			instance.rotate_y(rotation_y)
		if _allow_scale:
			var scale_factor = rng.randf_range(0.5, 2.0)
			instance.scale *= scale_factor
		add_child(instance)
		instances_created += 1
	estimated_instances = instances_created
	_generation_in_progress = false

func bake_instances():
	if get_child_count() == 0:
		return
	var stack = []
	stack.append_array(get_children())
	while stack.size() > 0:
		var node = stack.pop_back()
		node.set_owner(owner)
		stack.append_array(node.get_children())
