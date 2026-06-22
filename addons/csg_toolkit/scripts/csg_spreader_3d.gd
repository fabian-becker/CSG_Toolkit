@tool
class_name CSGSpreader3D extends CSGCombiner3D

const SPREADER_NODE_META = "SPREADER_NODE_META"
const MAX_INSTANCES = 20000

@export var template_node_path: NodePath:
	get:
		return _template_node_path
	set(value):
		_template_node_path = value
		_mark_dirty()

@export var hide_template: bool = true:
	get:
		return _hide_template
	set(value):
		_hide_template = value
		_update_template_visibility()

@export var spread_area_3d: Shape3D = null:
	get:
		return _spread_area_3d
	set(value):
		_spread_area_3d = value
		_mark_dirty()

@export var max_count: int = 10:
	get:
		return _max_count
	set(value):
		_max_count = clamp(value, 1, 100000)
		_mark_dirty()

@export_group("Spread Options")
@export var noise_threshold: float = 0.5:
	get:
		return _noise_threshold
	set(value):
		_noise_threshold = clamp(value, 0.0, 1.0)
		_mark_dirty()

@export var seed: int = 0:
	get:
		return _seed
	set(value):
		_seed = value
		_mark_dirty()

@export var allow_rotation: bool = false:
	get:
		return _allow_rotation
	set(value):
		_allow_rotation = value
		_mark_dirty()

@export var allow_scale: bool = false:
	get:
		return _allow_scale
	set(value):
		_allow_scale = value
		_mark_dirty()

@export var snap_distance: float = 0.0:
	get:
		return _snap_distance
	set(value):
		_snap_distance = value
		_mark_dirty()

@export_group("Collision Options")
@export var avoid_overlaps: bool = false:
	get:
		return _avoid_overlaps
	set(value):
		_avoid_overlaps = value
		_mark_dirty()

@export var min_distance: float = 1.0:
	get:
		return _min_distance
	set(value):
		_min_distance = max(0.0, value)
		_mark_dirty()

@export var max_placement_attempts: int = 100:
	get:
		return _max_placement_attempts
	set(value):
		_max_placement_attempts = clamp(value, 10, 1000)
		_mark_dirty()

@export var estimated_instances: int = 0

var rng: RandomNumberGenerator

var _dirty: bool = false
var _generation_in_progress: bool = false
var _template_node_path: NodePath
var _hide_template: bool = true
var _spread_area_3d: Shape3D = null
var _max_count: int = 10
var _noise_threshold: float = 0.5
var _seed: int = 0
var _allow_rotation: bool = false
var _allow_scale: bool = false
var _snap_distance: int = 0
var _avoid_overlaps: bool = false
var _min_distance: float = 1.0
var _max_placement_attempts: int = 100


func _ready() -> void:
	rng = RandomNumberGenerator.new()
	_mark_dirty()
	# Generate instances in-game on ready
	if not Engine.is_editor_hint():
		call_deferred("spread_template")


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	if _dirty and not _generation_in_progress:
		_dirty = false
		call_deferred("spread_template")


func _exit_tree() -> void:
	if not Engine.is_editor_hint():
		return
	clear_children()


func _mark_dirty() -> void:
	_dirty = true


func _update_template_visibility() -> void:
	if not is_inside_tree():
		return
	var template_node: Node = get_node_or_null(template_node_path)
	if template_node and template_node is Node3D:
		template_node.visible = not _hide_template


func clear_children() -> void:
	var children_to_remove: Array = []
	for child in get_children(true):
		if child.has_meta(SPREADER_NODE_META):
			children_to_remove.append(child)
	for child in children_to_remove:
		remove_child(child)
		child.queue_free()


func get_random_position_in_area() -> Vector3:
	var result: Vector3 = Vector3.ZERO
	if spread_area_3d is SphereShape3D:
		var radius: float = spread_area_3d.get_radius()
		var u: float = rng.randf()
		var v: float = rng.randf()
		var theta: float = u * TAU
		var phi: float = acos(2.0 * v - 1.0)
		var r: float = radius * pow(rng.randf(), 1.0 / 3.0)
		result = Vector3(r * sin(phi) * cos(theta), r * sin(phi) * sin(theta), r * cos(phi))
	elif spread_area_3d is BoxShape3D:
		var size: Vector3 = spread_area_3d.size
		result = Vector3(
			rng.randf_range(-size.x * 0.5, size.x * 0.5),
			rng.randf_range(-size.y * 0.5, size.y * 0.5),
			rng.randf_range(-size.z * 0.5, size.z * 0.5)
		)
	elif spread_area_3d is CapsuleShape3D:
		var radius: float = spread_area_3d.get_radius()
		var height: float = spread_area_3d.get_height() * 0.5
		if rng.randf() < noise_threshold:
			var angle: float = rng.randf() * TAU
			var r: float = radius * sqrt(rng.randf())
			result = Vector3(r * cos(angle), rng.randf_range(-height, height), r * sin(angle))
		else:
			var hemisphere_y: float = height if rng.randf() < noise_threshold else -height
			var u: float = rng.randf()
			var v: float = rng.randf()
			var theta: float = u * TAU
			var phi: float = acos(1.0 - v)
			var r: float = radius * pow(rng.randf(), 1.0 / 3.0)
			result = Vector3(
				r * sin(phi) * cos(theta),
				hemisphere_y + r * cos(phi) * (1 if hemisphere_y > 0 else -1),
				r * sin(phi) * sin(theta)
			)
	elif spread_area_3d is CylinderShape3D:
		var radius: float = spread_area_3d.get_radius()
		var height: float = spread_area_3d.get_height() * 0.5
		var angle: float = rng.randf() * TAU
		var r: float = radius * sqrt(rng.randf())
		result = Vector3(r * cos(angle), rng.randf_range(-height, height), r * sin(angle))
	elif spread_area_3d is HeightMapShape3D:
		var width: int = spread_area_3d.map_width
		var depth: int = spread_area_3d.map_depth
		if width > 0 and depth > 0 and spread_area_3d.map_data.size() > 0:
			var x: int = rng.randi_range(0, width - 1)
			var z: int = rng.randi_range(0, depth - 1)
			var index: int = x + z * width
			if index < spread_area_3d.map_data.size():
				result = Vector3(x, spread_area_3d.map_data[index], z)
	elif spread_area_3d is WorldBoundaryShape3D:
		var bound: float = 100.0
		result = Vector3(rng.randf_range(-bound, bound), 0, rng.randf_range(-bound, bound))
	elif spread_area_3d is ConvexPolygonShape3D or spread_area_3d is ConcavePolygonShape3D:
		var pts: PackedVector3Array = (
			spread_area_3d.points if spread_area_3d.has_method("get_points") else []
		)
		if pts.size() > 0:
			var min_point: Vector3 = pts[0]
			var max_point: Vector3 = pts[0]
			for p in pts:
				min_point = min_point.min(p)
				max_point = max_point.max(p)
			result = Vector3(
				rng.randf_range(min_point.x, max_point.x),
				rng.randf_range(min_point.y, max_point.y),
				rng.randf_range(min_point.z, max_point.z)
			)
	else:
		push_warning("CSGSpreader3D: Shape type not supported")
	return result


func spread_template() -> void:
	if _generation_in_progress:
		return
	_generation_in_progress = true
	if not spread_area_3d:
		_generation_in_progress = false
		return
	clear_children()
	var template_node: Node = get_node_or_null(template_node_path)
	if not template_node:
		_generation_in_progress = false
		return

	rng.seed = _seed
	var instances_created: int = 0
	var placed_positions: Array = []
	var budget: int = min(_max_count, MAX_INSTANCES)
	if _max_count > MAX_INSTANCES:
		push_warning(
			"CSGSpreader3D: max_count %s exceeds cap %s. Limiting." % [_max_count, MAX_INSTANCES]
		)
	for i in range(budget):
		var noise_value: float = rng.randf()
		if noise_value <= _noise_threshold:
			continue
		var position_found: bool = false
		var final_position: Vector3 = Vector3.ZERO
		var attempts: int = _max_placement_attempts if _avoid_overlaps else 1
		for attempt in range(attempts):
			var test_position: Vector3 = get_random_position_in_area()
			if not _avoid_overlaps:
				final_position = test_position
				position_found = true
				break
			var overlap: bool = false
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
		# Ensure instance is visible regardless of template visibility
		if instance is Node3D:
			instance.visible = true
		placed_positions.append(final_position)
		if _allow_rotation:
			var rotation_y: float = rng.randf_range(0, TAU)
			instance.rotate_y(rotation_y)
		if _allow_scale:
			var scale_factor: float = rng.randf_range(0.5, 2.0)
			instance.scale *= scale_factor
		add_child(instance)
		instances_created += 1
	estimated_instances = instances_created
	_update_template_visibility()
	_generation_in_progress = false


func bake_instances() -> void:
	if get_child_count() == 0:
		return
	var stack: Array = []
	stack.append_array(get_children())
	while stack.size() > 0:
		var node = stack.pop_back()
		node.set_owner(owner)
		stack.append_array(node.get_children())
