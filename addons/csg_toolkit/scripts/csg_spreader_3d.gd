@tool
class_name CSGSpreader3D extends CsgGeneratorBase

## Object distribution node with two placement modes:
##
## VOLUME -- scatter inside a movable, gizmo-editable area node
##   (CollisionShape3D with a shape, or any Node3D whose first CollisionShape3D
##   child defines the volume). The volume's transform defines where instances
##   appear, so it can be moved/rotated/scaled like any scene node and its
##   wireframe is visible in the viewport.
##
## SURFACE -- scatter on scene geometry. Candidate XY points are generated over
##   the area node's extents, raycast down (and up, for ceilings/overhangs)
##   against surface_targets, and instances are placed on the hit with optional
##   normal alignment. Works on plain CSG/mesh blockouts via a temporary
##   trimesh (no use_collision needed).

enum PlacementMode { VOLUME = 0, SURFACE = 1 }

const SURFACE_RAY_LENGTH := 10000.0
## Cell size for the overlap spatial hash, relative to min_distance.
const HASH_CELL_FACTOR := 1.0

# -- Area node ------------------------------------------------------------------------

## Node defining the spread volume/surface extent. Accepts a CollisionShape3D
## directly, or any Node3D containing one (first found is used). Position,
## rotation and scale of this node transform the volume.
var _area_node_path: NodePath
@export var area_node_path: NodePath:
	get: return _area_node_path
	set(value):
		_area_node_path = value
		_mark_dirty()

enum _SpreadShape { BOX, SPHERE, CYLINDER, CAPSULE, HEIGHTMAP, WORLD_BOUNDARY, NONE }

## Per-generation raycast cache (surface mode). Faces are pre-transformed to
## global space so per-ray work is plain triangle intersection -- no physics
## body setup needed for editor-time scattering.
var _mesh_cache: Dictionary = {}

var _max_count: int = 10
@export var max_count: int = 10:
	get: return _max_count
	set(value):
		_max_count = clamp(value, 1, 100000)
		_mark_dirty()

@export_group("Spread Options")
## VOLUME: probability gate for spawning an instance (density control).
## SURFACE: unused (density is governed by min_distance / max_count).
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

## VOLUME: random Y rotation. SURFACE: random yaw around the surface normal
## (before any normal alignment).
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

@export_group("Surface Placement")
## VOLUME scatters inside the area shape; SURFACE raycasts onto geometry.
var _placement_mode: PlacementMode = PlacementMode.VOLUME
@export var placement_mode: PlacementMode = PlacementMode.VOLUME:
	get: return _placement_mode
	set(value):
		_placement_mode = value
		_mark_dirty()

## SURFACE only: nodes to raycast against (MeshInstance3D, CSGShape3D,
## GridMap...). Empty = use every visual node under the scene root except the
## spreader's own subtree.
var _surface_targets: Array[NodePath] = []
@export var surface_targets: Array[NodePath] = []:
	get: return _surface_targets
	set(value):
		_surface_targets = value
		_mark_dirty()

## SURFACE: also cast upward and use the closest hit, so overhangs/ceilings
## receive instances. Slightly slower.
var _detect_overhangs: bool = false
@export var detect_overhangs: bool = false:
	get: return _detect_overhangs
	set(value):
		_detect_overhangs = value
		_mark_dirty()

## SURFACE: tilt instances so their up axis matches the surface normal.
var _align_to_normal: bool = false
@export var align_to_normal: bool = false:
	get: return _align_to_normal
	set(value):
		_align_to_normal = value
		_mark_dirty()

## SURFACE: reject hits whose normal deviates more than this many degrees from
## up (90 = accept walls too, 0 = flat ground only).
var _max_slope_degrees: float = 90.0
@export var max_slope_degrees: float = 90.0:
	get: return _max_slope_degrees
	set(value):
		_max_slope_degrees = clampf(value, 0.0, 90.0)
		_mark_dirty()

## SURFACE: offset applied along the surface normal after placement.
var _surface_offset: float = 0.0
@export var surface_offset: float = 0.0:
	get: return _surface_offset
	set(value):
		_surface_offset = value
		_mark_dirty()


# -- Area resolution ------------------------------------------------------------------

## Returns {node: Node3D, shape: Shape3D, xform: Transform3D} for the configured
## area node, or null. The transform is global and includes the shape node's
## own transform when the area node is a CollisionShape3D parent.
func _resolve_area() -> Variant:
	var area_node := get_node_or_null(_area_node_path)
	if area_node == null or not (area_node is Node3D):
		return null
	var shape_node: CollisionShape3D = null
	if area_node is CollisionShape3D:
		shape_node = area_node
	else:
		for child in area_node.get_children():
			if child is CollisionShape3D:
				shape_node = child
				break
	if shape_node == null or shape_node.shape == null:
		return null
	var xform: Transform3D = (area_node as Node3D).global_transform
	if shape_node != area_node:
		xform = xform * (shape_node as CollisionShape3D).transform
	return {"node": area_node, "shape": shape_node.shape, "xform": xform}


## Classification used by both sampling and surface extents.
func _classify_shape(shape: Shape3D) -> int:
	if shape is BoxShape3D: return _SpreadShape.BOX
	if shape is SphereShape3D: return _SpreadShape.SPHERE
	if shape is CylinderShape3D: return _SpreadShape.CYLINDER
	if shape is CapsuleShape3D: return _SpreadShape.CAPSULE
	if shape is HeightMapShape3D: return _SpreadShape.HEIGHTMAP
	if shape is WorldBoundaryShape3D: return _SpreadShape.WORLD_BOUNDARY
	return _SpreadShape.NONE


# -- Dependency watching ---------------------------------------------------------------

## The spreader's extra generation inputs: the area node (transform AND shape
## geometry -- resizing a BoxShape3D changes no transform) and, in surface
## mode, the explicit surface targets (existence + transforms).
func _compute_dependency_stamp() -> int:
	var parts: Array = []
	var area = _resolve_area()
	if area != null:
		parts.append((area["node"] as Node).get_instance_id())
		parts.append(area["xform"])
		parts.append(_shape_geometry_stamp(area["shape"]))
	else:
		parts.append(0)
	if _placement_mode == PlacementMode.SURFACE and not _surface_targets.is_empty():
		for path in _surface_targets:
			var node := get_node_or_null(path)
			if node == null:
				parts.append(0)
				continue
			parts.append(node.get_instance_id())
			if node is Node3D:
				parts.append((node as Node3D).global_transform)
	return hash(parts)


## Fingerprint of a shape's geometry: instance id (resource swap) plus every
## editor-visible property value. Generic — catches inspector resizes AND
## custom Shape3D subclasses (no per-type enumeration needed).
func _shape_geometry_stamp(shape: Shape3D) -> int:
	return _resource_stamp(shape)

# -- Volume sampling ------------------------------------------------------------------

## Samples a uniform random point inside the area shape in the AREA NODE's
## local space. Returns null for unsupported shapes (caller skips the attempt).
func _sample_volume_local(shape: Shape3D) -> Variant:
	match _classify_shape(shape):
		_SpreadShape.SPHERE:
			var radius: float = shape.get_radius()
			var theta := rng.randf() * TAU
			var phi := acos(2.0 * rng.randf() - 1.0)
			var r := radius * pow(rng.randf(), 1.0 / 3.0)
			return Vector3(r * sin(phi) * cos(theta), r * sin(phi) * sin(theta), r * cos(phi))
		_SpreadShape.BOX:
			var size: Vector3 = shape.size
			return Vector3(
				rng.randf_range(-size.x * 0.5, size.x * 0.5),
				rng.randf_range(-size.y * 0.5, size.y * 0.5),
				rng.randf_range(-size.z * 0.5, size.z * 0.5))
		_SpreadShape.CYLINDER:
			var angle := rng.randf() * TAU
			var r: float = shape.get_radius() * sqrt(rng.randf())
			return Vector3(r * cos(angle), rng.randf_range(-shape.get_height() * 0.5, shape.get_height() * 0.5), r * sin(angle))
		_SpreadShape.CAPSULE:
			var radius: float = shape.get_radius()
			var half: float = shape.get_height() * 0.5 - radius # cylinder shaft extent
			if rng.randf() < (half * 2.0) / (half * 2.0 + radius * 4.0 / 3.0):
				# Cylinder shaft, weighted by its volume share.
				var angle := rng.randf() * TAU
				var r := radius * sqrt(rng.randf())
				return Vector3(r * cos(angle), rng.randf_range(-half, half), r * sin(angle))
			# Hemispherical caps (uniform in sphere volume).
			var theta := rng.randf() * TAU
			var phi := acos(2.0 * rng.randf() - 1.0)
			var r := radius * pow(rng.randf(), 1.0 / 3.0)
			var y := half + r * cos(phi)
			return Vector3(r * sin(phi) * cos(theta), y, r * sin(phi) * sin(theta))
		_:
			return null


# -- Surface raycasting ---------------------------------------------------------------

## Builds (and caches) global-space triangle soups for every target node.
## MeshInstance3D targets use their mesh directly; CSG targets use their root
## combiner's current bake. Built once per generation, released after.
func _ensure_surface_space():
	_mesh_cache.clear()
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		return
	var wanted: Array = []
	if not _surface_targets.is_empty():
		for path in _surface_targets:
			var node := get_node_or_null(path)
			if node:
				wanted.append(node)
	else:
		_collect_visual_nodes(root, wanted)
	for node in wanted:
		if node == self or _is_descendant(self, node) or _is_descendant(node, self):
			continue
		_add_trimesh_for(node)


func _collect_visual_nodes(node: Node, out: Array):
	if node is MeshInstance3D:
		out.append(node)
	elif node is CSGShape3D:
		out.append(node)
	elif node is GridMap:
		out.append(node)
	for child in node.get_children():
		_collect_visual_nodes(child, out)


func _is_descendant(node: Node, ancestor: Node) -> bool:
	var cursor := node
	while cursor != null:
		if cursor == ancestor:
			return true
		cursor = cursor.get_parent()
	return false


## Raycasts against cached target triangle soups. Cheap AABB prefilter per
## target, then exact triangle intersection. Returns
## {position, normal, distance} in global space or null.
func _surface_ray(origin: Vector3, direction: Vector3) -> Variant:
	var best: Variant = null
	var ray_end := origin + direction * SURFACE_RAY_LENGTH
	for entry in _mesh_cache.values():
		# entry: {aabb: AABB (global), hits: Callable(origin, direction) -> Variant}
		var aabb: AABB = entry["aabb"]
		# AABB has no expand_to(); grow the zero-size segment box manually.
		var ray_box := AABB(origin.min(ray_end), Vector3.ZERO)
		ray_box = ray_box.expand(ray_end)
		if not ray_box.intersects(aabb):
			continue
		var hit: Variant = entry["hits"].call(origin, direction)
		if hit != null and (best == null or hit["distance"] < best["distance"]):
			best = hit
	return best


## Registers a target node: extracts an ArrayMesh (direct, duplicated, or CSG
## bake) and returns per-target hit closure data.
func _add_trimesh_for(node: Node):
	var mesh: Mesh = null
	var xform: Transform3D = Transform3D.IDENTITY
	if node is MeshInstance3D:
		mesh = (node as MeshInstance3D).mesh
		xform = (node as Node3D).global_transform
	elif node is CSGShape3D:
		# bake_static_mesh() is deferred by one frame; get_meshes() of the ROOT
		# shape is also deferred. For a non-root CSG child we walk up to its
		# root combiner and bake that instead.
		var csg := node as CSGShape3D
		var root_shape := csg
		while root_shape.get_parent() is CSGShape3D:
			root_shape = root_shape.get_parent()
		var meshes: Array = root_shape.get_meshes()
		mesh = meshes[1] if meshes.size() > 1 else null
		xform = (root_shape as Node3D).global_transform
	elif node is GridMap:
		# GridMap has no accessible mesh list; approximate with its cell AABBs
		# is overkill -- skip and warn once.
		return
	if mesh == null:
		return
	var faces: PackedVector3Array = []
	for surface in mesh.get_surface_count():
		var arrays: Array = mesh.surface_get_arrays(surface)
		if arrays[Mesh.ARRAY_VERTEX] == null:
			continue
		var tris: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else _triangulate_simple(arrays[Mesh.ARRAY_VERTEX])
		if tris.is_empty():
			continue
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for i in range(0, tris.size(), 3):
			# Transform to GLOBAL space immediately so per-ray work is cheap.
			faces.append((xform * verts[tris[i]]))
			faces.append((xform * verts[tris[i + 1]]))
			faces.append((xform * verts[tris[i + 2]]))
	if faces.is_empty():
		return
	var aabb := AABB(faces[0], Vector3.ZERO)
	for p in faces:
		aabb = aabb.expand(p)
	var tri_points: PackedVector3Array = faces
	_mesh_cache[node.get_instance_id()] = {
		"aabb": aabb,
		"hits": func (origin: Vector3, direction: Vector3) -> Variant:
			return _ray_vs_triangles(origin, direction, tri_points),
	}


func _ray_vs_triangles(origin: Vector3, direction: Vector3, tris: PackedVector3Array) -> Variant:
	var best: Variant = null
	var ray_end := origin + direction * SURFACE_RAY_LENGTH
	for i in range(0, tris.size(), 3):
		# Verified API: returns the intersection point (Vector3) or null.
		var hit_point: Variant = Geometry3D.segment_intersects_triangle(
			origin, ray_end, tris[i], tris[i + 1], tris[i + 2])
		if hit_point == null:
			continue
		var dist: float = origin.distance_to(hit_point)
		if best == null or dist < best["distance"]:
			var normal := (tris[i + 1] - tris[i]).cross(tris[i + 2] - tris[i]).normalized()
			best = {"position": hit_point, "normal": normal, "distance": dist}
	return best


func _triangulate_simple(verts: PackedVector3Array) -> PackedInt32Array:
	var indices: PackedInt32Array = []
	for i in range(0, verts.size() - 2, 3):
		indices.append(i)
		indices.append(i + 1)
		indices.append(i + 2)
	return indices


# -- Overlap rejection (spatial hash) ---------------------------------------------------

## Uniform-grid spatial hash over placed positions. Cell size is
## min_distance (or 1.0 if zero), so overlap checks only ever look at the
## 27 neighboring cells instead of every placed instance.
class _OverlapGrid:
	var cell_size: float
	var cells: Dictionary = {}

	func _init(p_cell_size: float):
		cell_size = maxf(p_cell_size, 0.001)

	func _key(p: Vector3) -> Vector3i:
		return Vector3i(floori(p.x / cell_size), floori(p.y / cell_size), floori(p.z / cell_size))

	func add(p: Vector3):
		cells.get_or_add(_key(p), []).append(p)

	func has_neighbor_within(p: Vector3, radius: float) -> bool:
		var r_cells := int(ceilf(radius / cell_size))
		var center := _key(p)
		for dx in range(-r_cells, r_cells + 1):
			for dy in range(-r_cells, r_cells + 1):
				for dz in range(-r_cells, r_cells + 1):
					if not cells.has(center + Vector3i(dx, dy, dz)):
						continue
					for existing in cells[center + Vector3i(dx, dy, dz)]:
						if p.distance_to(existing) < radius:
							return true
		return false


# -- Generation -------------------------------------------------------------------------

func _generate_instances():
	var area = _resolve_area()
	if area == null:
		push_warning("CSGSpreader3D: no area node/shape resolved; set area_node_path.")
		return
	var template_node = _get_template_node()
	if template_node == null:
		return

	rng.seed = _seed
	var grid: _OverlapGrid = _OverlapGrid.new(maxf(_min_distance, 0.001))
	var budget := min(_max_count, MAX_INSTANCES)
	if _max_count > MAX_INSTANCES:
		push_warning("CSGSpreader3D: max_count %s exceeds cap %s. Limiting." % [_max_count, MAX_INSTANCES])

	if _placement_mode == PlacementMode.VOLUME:
		estimated_instances = _generate_volume(area, template_node, budget, grid)
	else:
		estimated_instances = _generate_surface(area, template_node, budget, grid)

	_release_surface_data()


func _generate_volume(area: Dictionary, template_node: Node, budget: int, grid: _OverlapGrid) -> int:
	var xform: Transform3D = area["xform"]
	var shape: Shape3D = area["shape"]
	var created := 0
	for i in range(budget):
		if rng.randf() <= _noise_threshold and _noise_threshold < 1.0:
			continue
		var attempts := _max_placement_attempts if _avoid_overlaps else 1
		for attempt in range(attempts):
			var local = _sample_volume_local(shape)
			if local == null:
				break
			var test_position: Vector3 = xform * local
			if _avoid_overlaps and grid.has_neighbor_within(test_position, _min_distance):
				continue
			if _make_placed_instance(template_node, test_position, Vector3.UP, grid):
				created += 1
			break
	return created


func _generate_surface(area: Dictionary, template_node: Node, budget: int, grid: _OverlapGrid) -> int:
	_ensure_surface_space()
	if _mesh_cache.is_empty():
		push_warning("CSGSpreader3D: no surface targets found.")
		return 0
	var xform: Transform3D = area["xform"]
	var aabb := _area_world_aabb(area)
	if aabb.size == Vector3.ZERO:
		return 0
	var cos_slope := cos(deg_to_rad(_max_slope_degrees))
	var up := Vector3.UP
	var created := 0
	for i in range(budget):
		# XY candidate over the area node's footprint, cast downward.
		var local := Vector3(rng.randf_range(-0.5, 0.5) * aabb.size.x, 0, rng.randf_range(-0.5, 0.5) * aabb.size.z)
		var candidate := xform * (local + Vector3(0, aabb.size.y * 0.5 + 1.0, 0))
		var hit = _surface_ray(candidate, Vector3.DOWN)
		if _detect_overhangs:
			var from_below := xform * (local - Vector3(0, aabb.size.y * 0.5 + 1.0, 0))
			var hit_up = _surface_ray(from_below, Vector3.UP)
			if hit_up != null and (hit == null or hit_up["distance"] < hit["distance"]):
				hit = hit_up
		if hit == null:
			continue
		if up.dot(hit["normal"] as Vector3) < cos_slope:
			continue
		var pos: Vector3 = (hit["position"] as Vector3) + (hit["normal"] as Vector3) * _surface_offset
		if _avoid_overlaps and grid.has_neighbor_within(pos, _min_distance):
			continue
		if _make_placed_instance(template_node, pos, hit["normal"], grid):
			created += 1
	return created


## Positions an instance and applies placement variations. Returns true when
## the instance was created.
func _make_placed_instance(template_node: Node, position: Vector3, normal: Vector3, grid: _OverlapGrid) -> bool:
	var instance = _make_instance(template_node, position)
	if instance == null:
		return false
	var node3d := instance as Node3D
	if _placement_mode == PlacementMode.SURFACE and _align_to_normal:
		_align_to_surface_normal(node3d, normal)
		if _allow_rotation:
			node3d.rotate_object_local(Vector3.UP, rng.randf() * TAU)
	elif _allow_rotation:
		_apply_random_y_rotation(node3d)
	if _allow_scale:
		_apply_random_scale(node3d, 0.5, 2.0)
	grid.add(position)
	return true


func _align_to_surface_normal(node3d: Node3D, normal: Vector3) -> void:
	# Gram-Schmidt: build a right-handed basis with Y = surface normal while
	# keeping the instance's forward direction as stable as possible.
	# Order matters: right = up x forward / forward = right x up keeps det = +1
	# (the reverse order mirrors the instance).
	var up := normal.normalized()
	var old_forward := node3d.global_transform.basis.z
	if absf(up.dot(old_forward)) > 0.999:
		old_forward = node3d.global_transform.basis.x
	var right := up.cross(old_forward).normalized()
	var forward := right.cross(up).normalized()
	node3d.global_transform.basis = Basis(right, up, forward)


## Surface mode: extent of the area shape in world space (used for candidate
## generation). Only box-ish extents are needed -- raycasting does the rest.
func _area_world_aabb(area: Dictionary) -> AABB:
	var shape: Shape3D = area["shape"]
	var xform: Transform3D = area["xform"]
	match _classify_shape(shape):
		_SpreadShape.BOX:
			return xform * AABB(-shape.size * 0.5, shape.size)
		_SpreadShape.SPHERE:
			var r: float = shape.get_radius()
			return xform * AABB(Vector3.ONE * -r, Vector3.ONE * r * 2.0)
		_SpreadShape.CYLINDER:
			var r: float = shape.get_radius()
			var h: float = shape.get_height()
			return xform * AABB(Vector3(-r, -h * 0.5, -r), Vector3(r * 2.0, h, r * 2.0))
		_SpreadShape.CAPSULE:
			var r: float = shape.get_radius()
			var h: float = shape.get_height() + r * 2.0
			return xform * AABB(Vector3(-r, -h * 0.5, -r), Vector3(r * 2.0, h, r * 2.0))
		_:
			# Generic fallback: unit cube scaled by the node's global scale.
			var s: Vector3 = xform.basis.get_scale()
			return xform * AABB(-s * 0.5, s)


## Drops temporary raycast data.
func _release_surface_data():
	_mesh_cache.clear()


func get_instance_count() -> int:
	if _placement_mode == PlacementMode.SURFACE:
		return 0 # depends on geometry; unknown without generating
	return _max_count if _resolve_area() != null else 0
