@tool
class_name CSGSpreader3D extends CsgGeneratorBase

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
## Probability gate for spawning an instance (acts as a density control).
## (The unrelated capsule hemisphere use was removed -- capsule sampling no
## longer branches on it.)
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

## When > 0, instances are placed on the shape's surface instead of inside its
## volume, pushed outward by this distance. 0 keeps volume placement.
var _snap_distance: float = 0.0
@export var snap_distance: float = 0.0:
	get: return _snap_distance
	set(value):
		_snap_distance = max(0.0, value)
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

## Samples a random point inside the spread area -- or on its surface when
## snap_distance > 0. Returns null when the shape type is unsupported so the
## caller can skip the attempt instead of stacking instances at the origin.
func get_random_position_in_area() -> Variant:
	var position = _sample_shape_volume()
	if position == null:
		return null
	if _snap_distance > 0.0:
		return _project_to_surface(position)
	return position

## Pure per-shape volume sampling. Returns null for unsupported shapes.
func _sample_shape_volume() -> Variant:
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
		if rng.randf() < 0.5:
			# Cylinder shaft of the capsule.
			var angle = rng.randf() * TAU
			var r = radius * sqrt(rng.randf())
			return Vector3(r * cos(angle), rng.randf_range(-height, height), r * sin(angle))
		else:
			# Hemispherical caps, chosen uniformly.
			var hemisphere_y = height if rng.randf() < 0.5 else -height
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
			return null
		# Convert grid coordinates to world units with bilinear height filtering.
		var x = rng.randf_range(0.0, float(width - 1))
		var z = rng.randf_range(0.0, float(depth - 1))
		var x0 = int(x)
		var z0 = int(z)
		var fx = x - x0
		var fz = z - z0
		var x1 = min(x0 + 1, width - 1)
		var z1 = min(z0 + 1, depth - 1)
		var h00: float = spread_area_3d.map_data[x0 + z0 * width]
		var h10: float = spread_area_3d.map_data[x1 + z0 * width]
		var h01: float = spread_area_3d.map_data[x0 + z1 * width]
		var h11: float = spread_area_3d.map_data[x1 + z1 * width]
		var top = lerpf(h00, h10, fx)
		var bottom = lerpf(h01, h11, fx)
		return Vector3(x, lerpf(top, bottom, fz), z)
	if spread_area_3d is WorldBoundaryShape3D:
		var bound = 100.0
		return Vector3(rng.randf_range(-bound, bound), 0, rng.randf_range(-bound, bound))
	if spread_area_3d is ConvexPolygonShape3D or spread_area_3d is ConcavePolygonShape3D:
		var pts = spread_area_3d.points if spread_area_3d.has_method("get_points") else []
		if pts.size() == 0:
			return null
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
	# Unsupported shape: signal the caller to skip rather than pile up at origin.
	return null

func _generate_instances():
	if not spread_area_3d:
		return
	var template_node = _get_template_node()
	if template_node == null:
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
			if test_position == null:
				continue
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
		var instance = _make_instance(template_node, final_position)
		if instance == null:
			continue
		placed_positions.append(final_position)
		if _allow_rotation:
			_apply_random_y_rotation(instance)
		if _allow_scale:
			_apply_random_scale(instance, 0.5, 2.0)
		instances_created += 1
	estimated_instances = instances_created

## Backward-compatible alias for the old API used by tooling.
func spread_template():
	refresh()

func get_instance_count() -> int:
	return _max_count if spread_area_3d else 0

## Projects a sampled interior point onto the shape's surface, pushed outward
## by snap_distance along the direction from the shape center. This gives a
## "scatter on the surface shell" effect without needing scene raycasting.
func _project_to_surface(position: Vector3) -> Vector3:
	if spread_area_3d is HeightMapShape3D:
		# Heightmap already is a surface: keep the sampled height, push up.
		return Vector3(position.x, position.y + _snap_distance, position.z)
	if spread_area_3d is WorldBoundaryShape3D:
		# Already planar; snapping is a no-op beyond a y-offset.
		return Vector3(position.x, _snap_distance, position.z)
	if spread_area_3d is ConvexPolygonShape3D or spread_area_3d is ConcavePolygonShape3D:
		# Push the point to the farthest extent along the dominant axis of its
		# offset from the shape's AABB center.
		var pts = spread_area_3d.points if spread_area_3d.has_method("get_points") else []
		if pts.is_empty():
			return position
		var min_point = pts[0]
		var max_point = pts[0]
		for p in pts:
			min_point = min_point.min(p)
			max_point = max_point.max(p)
		var aabb := AABB(min_point, max_point - min_point)
		var center_to_point := position - aabb.get_center()
		var dominant := Vector3.ZERO
		if absf(center_to_point.x) >= absf(center_to_point.y) and absf(center_to_point.x) >= absf(center_to_point.z):
			dominant = Vector3(signf(center_to_point.x), 0, 0)
		elif absf(center_to_point.y) >= absf(center_to_point.z):
			dominant = Vector3(0, signf(center_to_point.y), 0)
		else:
			dominant = Vector3(0, 0, signf(center_to_point.z))
		return position + dominant * _snap_distance
	# Generic radial projection for sphere-like shapes (box/capsule/cylinder are
	# approximated radially -- good enough for scatter shells).
	var dir := position
	if dir.length() < 0.001:
		dir = Vector3.FORWARD
	return dir.normalized() * (dir.length() + _snap_distance)
