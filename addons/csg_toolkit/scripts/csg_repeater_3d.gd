@tool
class_name CSGRepeater3D extends CSGCombiner3D

# NOTE: Registered as custom type in plugin (csg_toolkit.gd) inheriting CSGCombiner3D.
# Ensure pattern resource scripts are loaded (Godot should handle via class_name, but we force references for safety):
const _REF_GRID = preload("res://addons/csg_toolkit/scripts/patterns/grid_pattern.gd") # ensure subclass scripts loaded
const _REF_CIRC = preload("res://addons/csg_toolkit/scripts/patterns/circular_pattern.gd")
const _REF_SPIRAL = preload("res://addons/csg_toolkit/scripts/patterns/spiral_pattern.gd")
const _REF_NOISE = preload("res://addons/csg_toolkit/scripts/patterns/noise_pattern.gd")

const REPEATER_NODE_META = "REPEATED_NODE_META"
const MAX_INSTANCES = 20000

var _dirty: bool = false
var _template_node_path: NodePath
@export var template_node_path: NodePath:
	get: return _template_node_path
	set(value):
		_template_node_path = value
		_mark_dirty()

var _template_node_scene: PackedScene
@export var template_node_scene: PackedScene:
	get: return _template_node_scene
	set(value):
		_template_node_scene = value
		_mark_dirty()

var _hide_template: bool = true
@export var hide_template: bool = true:
	get: return _hide_template
	set(value):
		_hide_template = value
		_update_template_visibility()

## repeat & spacing removed (migrated into pattern resources)

@export_group("Pattern Options")
# A single exported pattern resource (`pattern`) defines generation behavior.


@export_group("Variation Options")
# Rotation variation properties now managed via custom property list for collapsible enable group.
var _randomize_rotation: bool = false
var randomize_rotation: bool:
	get: return _randomize_rotation
	set(value):
		_randomize_rotation = value
		_mark_dirty()
		notify_property_list_changed()

var _randomize_rot_x: bool = false
var randomize_rot_x: bool:
	get: return _randomize_rot_x
	set(value):
		_randomize_rot_x = value
		if _randomize_rotation: _mark_dirty()
		notify_property_list_changed()

var _randomize_rot_y: bool = false
var randomize_rot_y: bool:
	get: return _randomize_rot_y
	set(value):
		_randomize_rot_y = value
		if _randomize_rotation: _mark_dirty()
		notify_property_list_changed()

var _randomize_rot_z: bool = false
var randomize_rot_z: bool:
	get: return _randomize_rot_z
	set(value):
		_randomize_rot_z = value
		if _randomize_rotation: _mark_dirty()
		notify_property_list_changed()

# Per-axis rotation variance in degrees (0 = full 0..360 random for that axis; >0 jitters around original)
var _rotation_variance_x_deg: float = 0.0
var rotation_variance_x_deg: float:
	get: return _rotation_variance_x_deg
	set(value):
		_rotation_variance_x_deg = clamp(value, 0.0, 360.0)
		if _randomize_rotation and _randomize_rot_x: _mark_dirty()

var _rotation_variance_y_deg: float = 0.0
var rotation_variance_y_deg: float:
	get: return _rotation_variance_y_deg
	set(value):
		_rotation_variance_y_deg = clamp(value, 0.0, 360.0)
		if _randomize_rotation and _randomize_rot_y: _mark_dirty()

var _rotation_variance_z_deg: float = 0.0
var rotation_variance_z_deg: float:
	get: return _rotation_variance_z_deg
	set(value):
		_rotation_variance_z_deg = clamp(value, 0.0, 360.0)
		if _randomize_rotation and _randomize_rot_z: _mark_dirty()

var _randomize_scale: bool = false
var randomize_scale: bool:
	get: return _randomize_scale
	set(value):
		_randomize_scale = value
		_mark_dirty()
		notify_property_list_changed()

var _scale_variance: float = 0.0
var scale_variance: float:
	get: return _scale_variance
	set(value):
		_scale_variance = clamp(value, 0.0, 1.0)
		if _randomize_scale:
			_mark_dirty()

# Per-axis scale variance (if zero => use global variance when axis toggle active)
var _scale_variance_x: float = 0.0
var scale_variance_x: float:
	get: return _scale_variance_x
	set(value):
		_scale_variance_x = clamp(value, 0.0, 1.0)
		if _randomize_scale and _randomize_scale_x: _mark_dirty()

var _scale_variance_y: float = 0.0
var scale_variance_y: float:
	get: return _scale_variance_y
	set(value):
		_scale_variance_y = clamp(value, 0.0, 1.0)
		if _randomize_scale and _randomize_scale_y: _mark_dirty()

var _scale_variance_z: float = 0.0
var scale_variance_z: float:
	get: return _scale_variance_z
	set(value):
		_scale_variance_z = clamp(value, 0.0, 1.0)
		if _randomize_scale and _randomize_scale_z: _mark_dirty()

# Per-axis scale randomization toggles (optional – if none enabled acts as uniform variance on all axes)
var _randomize_scale_x: bool = false
var randomize_scale_x: bool:
	get: return _randomize_scale_x
	set(value):
		_randomize_scale_x = value
		if _randomize_scale: _mark_dirty()
		notify_property_list_changed()

var _randomize_scale_y: bool = false
var randomize_scale_y: bool:
	get: return _randomize_scale_y
	set(value):
		_randomize_scale_y = value
		if _randomize_scale: _mark_dirty()
		notify_property_list_changed()

var _randomize_scale_z: bool = false
var randomize_scale_z: bool:
	get: return _randomize_scale_z
	set(value):
		_randomize_scale_z = value
		if _randomize_scale: _mark_dirty()
		notify_property_list_changed()

var _position_jitter: float = 0.0
@export var position_jitter: float = 0.0:
	get: return _position_jitter
	set(value):
		_position_jitter = max(0.0, value)
		_mark_dirty()

var _random_seed: int = 0
@export var random_seed: int = 0:
	get: return _random_seed
	set(value):
		_random_seed = value
		_mark_dirty()

# Estimated instance count (read-only in inspector; updated internally)
@export var estimated_instances: int = 0

var rng: RandomNumberGenerator
var _generation_in_progress := false
var _pattern: CSGPattern
@export var pattern: CSGPattern:
	get: return _pattern
	set(value):
		if value == _pattern:
			return
		# Reject non-CSGPattern resources
		if value != null and not (value is CSGPattern):
			push_warning("Assigned pattern is not a CSGPattern-derived resource; ignoring.")
			return
		# Prevent assigning the abstract base directly (must use subclass)
		if value != null and value.get_class() == "CSGPattern":
			push_warning("Cannot assign base CSGPattern directly. Please use a concrete pattern (Grid, Circular, Spiral...).")
			return
		# Disconnect old
		if _pattern and _pattern.is_connected("changed", Callable(self, "_on_pattern_changed")):
			_pattern.disconnect("changed", Callable(self, "_on_pattern_changed"))
		_pattern = value
		if _pattern and not _pattern.is_connected("changed", Callable(self, "_on_pattern_changed")):
			_pattern.connect("changed", Callable(self, "_on_pattern_changed"))
		_mark_dirty()

func _ready():
	rng = RandomNumberGenerator.new()
	# Provide a default pattern if none assigned (through setter for signal wiring).
	if pattern == null:
		pattern = CSGGridPattern.new()
	_mark_dirty()
	# Generate instances in-game on ready
	if not Engine.is_editor_hint():
		call_deferred("repeat_template")

func _on_pattern_changed():
	# Called when the assigned pattern resource's exported properties are edited in inspector.
	_mark_dirty()

func _process(_delta):
	if not Engine.is_editor_hint(): return
	if _dirty and not _generation_in_progress:
		_dirty = false
		call_deferred("repeat_template")

func _exit_tree():
	# Clean up any remaining repeated nodes
	clear_children()

func _mark_dirty():
	_dirty = true

func _update_template_visibility():
	if not is_inside_tree():
		return
	var template_node = get_node_or_null(template_node_path)
	if template_node and template_node is Node3D:
		template_node.visible = not _hide_template

func clear_children():
	# Clear existing children except the template node
	var children_to_remove = []
	for child in get_children(true):
		if child.has_meta(REPEATER_NODE_META):
			children_to_remove.append(child)
	# Remove children immediately for better performance
	for child in children_to_remove:
		remove_child(child)
		child.queue_free()

func repeat_template():
	if _generation_in_progress:
		return
	_generation_in_progress = true
	clear_children()

	var template_node = get_node_or_null(template_node_path)
	var using_scene = false
	# Determine template source
	if not template_node:
		if not template_node_scene or not template_node_scene.can_instantiate():
			_generation_in_progress = false
			return
		template_node = template_node_scene.instantiate()
		using_scene = true
		add_child(template_node)

	# Use pattern estimation for cap check
	var template_size := _get_template_size(template_node)
	var ctx_cap := {"template_size": template_size, "rng": rng, "position_jitter": _position_jitter}
	var estimate := 0
	if pattern:
		estimate = pattern.get_estimated_count(ctx_cap)
	if estimate <= 1:
		if using_scene:
			remove_child(template_node)
			template_node.queue_free()
		_generation_in_progress = false
		return
	if estimate > MAX_INSTANCES:
		push_warning("CSGRepeater3D: Estimated count %s exceeds cap %s. Aborting generation." % [estimate, MAX_INSTANCES])
		_generation_in_progress = false
		return

	rng.seed = _random_seed
	# template_size already computed earlier (template_size variable)
	var positions = _generate_positions(template_size)
	estimated_instances = positions.size() - 1

	for i in range(positions.size()):
		var position = positions[i]
		if i == 0 and position.is_zero_approx():
			continue
		var instance = template_node.duplicate()
		if instance == null:
			continue
		instance.set_meta(REPEATER_NODE_META, true)
		instance.transform.origin = position
		# Ensure instance is visible regardless of template visibility
		if instance is Node3D:
			instance.visible = true
		_apply_variations(instance)
		add_child(instance)

	if using_scene:
		remove_child(template_node)
		template_node.queue_free()
	else:
		_update_template_visibility()
	_generation_in_progress = false

func _generate_positions(template_size: Vector3) -> Array:
	var ctx: Dictionary = {"template_size": template_size, "rng": rng, "position_jitter": _position_jitter}
	if pattern == null:
		return []
	return pattern.generate(ctx)


# -- Geometry-based spacing helpers -------------------------------------------------

func _get_template_size(template_node: Node) -> Vector3:
	if template_node == null or not (template_node is Node3D):
		return Vector3.ONE
	var aabb := _get_combined_aabb(template_node)
	var size: Vector3 = aabb.size
	if size.x <= 0.0001: size.x = 1.0
	if size.y <= 0.0001: size.y = 1.0
	if size.z <= 0.0001: size.z = 1.0
	return size

func _get_combined_aabb(node: Node) -> AABB:
	var found := false
	var combined := AABB()
	if node is Node3D and node.has_method("get_aabb"):
		var aabb = node.get_aabb()
		combined = aabb
		found = true
	for child in node.get_children():
		if child is Node3D:
			var child_aabb = _get_combined_aabb(child)
			if child_aabb.size != Vector3.ZERO:
				if not found:
					combined = child_aabb
					found = true
				else:
					combined = combined.merge(child_aabb)
	return combined if found else AABB(Vector3.ZERO, Vector3.ZERO)

func _apply_material_recursive(node: Node, material: Material):
	if node is CSGShape3D:
		node.material_override = material
	for child in node.get_children():
		_apply_material_recursive(child, material)


func _apply_variations(instance: Node3D):
	if _randomize_rotation:
		var final_rot := instance.rotation
		if _randomize_rot_x:
			if _rotation_variance_x_deg > 0.0:
				final_rot.x += rng.randf_range(-deg_to_rad(_rotation_variance_x_deg), deg_to_rad(_rotation_variance_x_deg))
			else:
				final_rot.x = rng.randf() * TAU
		if _randomize_rot_y:
			if _rotation_variance_y_deg > 0.0:
				final_rot.y += rng.randf_range(-deg_to_rad(_rotation_variance_y_deg), deg_to_rad(_rotation_variance_y_deg))
			else:
				final_rot.y = rng.randf() * TAU
		if _randomize_rot_z:
			if _rotation_variance_z_deg > 0.0:
				final_rot.z += rng.randf_range(-deg_to_rad(_rotation_variance_z_deg), deg_to_rad(_rotation_variance_z_deg))
			else:
				final_rot.z = rng.randf() * TAU
		instance.rotation = final_rot
	if _randomize_scale:
		# If any axis toggles are on, apply independent variance per axis; else uniform.
		var use_axes = _randomize_scale_x or _randomize_scale_y or _randomize_scale_z
		if use_axes:
			var sx = instance.scale.x
			var sy = instance.scale.y
			var sz = instance.scale.z
			if _randomize_scale_x:
				var vx = (_scale_variance_x if _scale_variance_x > 0.0 else _scale_variance)
				sx *= max(0.1, 1.0 + rng.randf_range(-vx, vx))
			if _randomize_scale_y:
				var vy = (_scale_variance_y if _scale_variance_y > 0.0 else _scale_variance)
				sy *= max(0.1, 1.0 + rng.randf_range(-vy, vy))
			if _randomize_scale_z:
				var vz = (_scale_variance_z if _scale_variance_z > 0.0 else _scale_variance)
				sz *= max(0.1, 1.0 + rng.randf_range(-vz, vz))
			instance.scale = Vector3(sx, sy, sz)
		else:
			var scale_factor = max(0.1, 1.0 + rng.randf_range(-_scale_variance, _scale_variance))
			instance.scale *= scale_factor

func regenerate():
	_mark_dirty()

# -- Custom property list (Godot 4.5 group enable support) -------------------------
func _get_property_list() -> Array:
	var props: Array = []

	# Keep default exported properties (engine already exposes them). Only inject
	# the rotation variation cluster with group enable + subgroup organization.

	# Group header for random rotation feature.
	# Variation Options parent group
	props.append({
		"name": "Variation Options",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_GROUP
	})
	# Rotation subgroup under Variation Options
	props.append({
		"name": "Rotation Randomization",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_SUBGROUP
	})
	# Enabling checkbox on group header via PROPERTY_HINT_GROUP_ENABLE.
	props.append({
		"name": "randomize_rotation",
		"type": TYPE_BOOL,
		"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
		"hint": PROPERTY_HINT_GROUP_ENABLE
	})
	# Per-axis random toggles
	props.append(_prop_bool("randomize_rot_x"))
	if _randomize_rotation and _randomize_rot_x:
		props.append({
			"name": "rotation_variance_x_deg",
			"type": TYPE_FLOAT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,360,0.1,degrees",
			"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR
		})
	props.append(_prop_bool("randomize_rot_y"))
	if _randomize_rotation and _randomize_rot_y:
		props.append({
			"name": "rotation_variance_y_deg",
			"type": TYPE_FLOAT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,360,0.1,degrees",
			"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR
		})
	props.append(_prop_bool("randomize_rot_z"))
	if _randomize_rotation and _randomize_rot_z:
		props.append({
			"name": "rotation_variance_z_deg",
			"type": TYPE_FLOAT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,360,0.1,degrees",
			"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR
		})

	# Subgroup for locked rotations (should reside inside Rotation Randomization group)
	# (Locked rotations removed as per user request)

	# Scale variation subgroup under Variation Options
	props.append({
		"name": "Scale Variation",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_SUBGROUP
	})
	props.append({
		"name": "randomize_scale",
		"type": TYPE_BOOL,
		"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
		"hint": PROPERTY_HINT_GROUP_ENABLE
	})
	props.append(_prop_float_range("scale_variance", "0,1,0.01"))
	props.append(_prop_bool("randomize_scale_x"))
	if _randomize_scale and _randomize_scale_x:
		props.append(_prop_float_range("scale_variance_x", "0,1,0.01"))
	props.append(_prop_bool("randomize_scale_y"))
	if _randomize_scale and _randomize_scale_y:
		props.append(_prop_float_range("scale_variance_y", "0,1,0.01"))
	props.append(_prop_bool("randomize_scale_z"))
	if _randomize_scale and _randomize_scale_z:
		props.append(_prop_float_range("scale_variance_z", "0,1,0.01"))

	return props

func _prop_bool(name: String) -> Dictionary:
	return {
		"name": name,
		"type": TYPE_BOOL,
		"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR
	}

func _prop_float_deg(name: String, value: float) -> Dictionary:
	return {
		"name": name,
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "-360,360,0.1,degrees",
		"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR
	}

func _prop_float_range(name: String, hint_str: String) -> Dictionary:
	return {
		"name": name,
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": hint_str,
		"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR
	}

func get_instance_count() -> int:
	if pattern == null:
		return 0
	var ctx := {"template_size": Vector3.ONE, "rng": rng, "position_jitter": _position_jitter}
	return max(0, pattern.get_estimated_count(ctx) - 1)

func apply_template():
	if get_child_count() == 0:
		return
	var stack = []
	stack.append_array(get_children())
	while stack.size() > 0:
		var node = stack.pop_back()
		node.set_owner(owner)
		stack.append_array(node.get_children())

# Alias for clarity in UI
func bake_instances():
	apply_template()
