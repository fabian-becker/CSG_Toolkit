@tool
class_name CSGRepeater3D extends CsgGeneratorBase

# NOTE: Registered as custom type in plugin (csg_toolkit.gd) inheriting CSGCombiner3D.
# Ensure pattern resource scripts are loaded (Godot should handle via class_name, but we force references for safety):
const _REF_GRID = preload("res://addons/csg_toolkit/scripts/patterns/grid_pattern.gd") # ensure subclass scripts loaded
const _REF_CIRC = preload("res://addons/csg_toolkit/scripts/patterns/circular_pattern.gd")
const _REF_SPIRAL = preload("res://addons/csg_toolkit/scripts/patterns/spiral_pattern.gd")

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

## Position jitter variation (per-axis, managed via custom property list).
var _randomize_position: bool = false
var randomize_position: bool:
	get: return _randomize_position
	set(value):
		_randomize_position = value
		_mark_dirty()
		notify_property_list_changed()

## Per-axis maximum random offset applied to each instance position.
var _position_jitter: Vector3 = Vector3.ZERO
var position_jitter: Vector3:
	get: return _position_jitter
	set(value):
		_position_jitter = Vector3(maxf(0.0, value.x), maxf(0.0, value.y), maxf(0.0, value.z))
		_mark_dirty()

var _random_seed: int = 0
@export var random_seed: int = 0:
	get: return _random_seed
	set(value):
		_random_seed = value
		_mark_dirty()

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
		# Prevent assigning the abstract base directly (must use subclass).
		# NOTE: get_class() returns the native class for scripted resources, so
		# check the script's global class_name instead.
		if value != null and value.get_script() != null and value.get_script().get_global_name() == "CSGPattern":
			push_warning("Cannot assign base CSGPattern directly. Please use a concrete pattern (Grid, Circular, Spiral...).")
			return
		# Disconnect old
		if _pattern and _pattern.changed.is_connected(_on_pattern_changed):
			_pattern.changed.disconnect(_on_pattern_changed)
		_pattern = value
		if _pattern and not _pattern.changed.is_connected(_on_pattern_changed):
			_pattern.changed.connect(_on_pattern_changed)
		_mark_dirty()


func _setup_generator() -> void:
	# Provide a default pattern if none assigned (through setter for signal wiring).
	if pattern == null:
		pattern = CSGGridPattern.new()

func _on_pattern_changed():
	# Only fires for resources that explicitly emit_changed(); plain scripted
	# patterns do not on inspector edits. The dependency watcher covers those.
	_mark_dirty()


## The pattern resource is a generation input. Plain scripted resources don't
## emit Resource.changed on inspector edits, so it's fingerprinted here.
func _compute_dependency_stamp() -> int:
	return _resource_stamp(pattern)

func _generate_instances():
	var template_node = _get_template_node()
	if template_node == null:
		return
	var using_scene := _pending_template_instance != null

	# Use pattern estimation for cap check
	var template_size := _get_template_size(template_node)
	var estimate := 0
	if pattern:
		estimate = pattern.get_estimated_count({"template_size": template_size, "rng": rng})
	if estimate > MAX_INSTANCES:
		push_warning("CSGRepeater3D: Estimated count %s exceeds cap %s. Aborting generation." % [estimate, MAX_INSTANCES])
		if using_scene:
			_release_template_instance()
		return

	rng.seed = _random_seed
	var instance_positions = _instance_positions(template_node, template_size)
	estimated_instances = instance_positions.size()

	for position in instance_positions:
		var instance = _make_instance(template_node, position)
		if instance == null:
			continue
		_apply_variations(instance)

	if using_scene:
		_release_template_instance()

## Filters raw pattern positions into instance placements. The template node
## itself already occupies its own origin (e.g. a grid pattern's (0,0,0) entry),
## so positions coinciding with the template's origin are not duplicated there.
## Unlike the old first-index heuristic this works regardless of the order in
## which a pattern emits its positions.
func _instance_positions(template_node: Node, template_size: Vector3) -> Array:
	var result: Array = []
	if pattern == null:
		return result
	var template_origin: Vector3 = (template_node as Node3D).transform.origin if template_node is Node3D else Vector3.ZERO
	# max_instances: master's contract, consumed by noise_pattern for its
	# hard generation cap; harmless to other patterns.
	var ctx: Dictionary = {"template_size": template_size, "rng": rng, "max_instances": MAX_INSTANCES}
	for position in pattern.generate(ctx):
		if position == template_origin:
			continue
		result.append(position)
	return result


func _apply_variations(instance: Node3D):
	# Position jitter: independent per-axis random offset around the pattern
	# position (applied here so every pattern type gets it, not just grid).
	if _randomize_position:
		instance.transform.origin += Vector3(
			rng.randf_range(-_position_jitter.x, _position_jitter.x),
			rng.randf_range(-_position_jitter.y, _position_jitter.y),
			rng.randf_range(-_position_jitter.z, _position_jitter.z))
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
	refresh()

# -- Custom property list (Godot 4.5 group enable support) -------------------------
func _get_property_list() -> Array[Dictionary]:
	var props: Array[Dictionary] = super._get_property_list()

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

	# Position jitter subgroup under Variation Options
	props.append({
		"name": "Position Jitter",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_SUBGROUP
	})
	props.append({
		"name": "randomize_position",
		"type": TYPE_BOOL,
		"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
		"hint": PROPERTY_HINT_GROUP_ENABLE
	})
	if _randomize_position:
		props.append(_prop_float_range("position_jitter_x", "0,1000,0.01"))
		props.append(_prop_float_range("position_jitter_y", "0,1000,0.01"))
		props.append(_prop_float_range("position_jitter_z", "0,1000,0.01"))

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

func _prop_float_range(name: String, hint_str: String) -> Dictionary:
	return {
		"name": name,
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": hint_str,
		"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR
	}


## Maps the synthetic per-axis jitter properties onto the Vector3 backing var.
func _get(property: StringName) -> Variant:
	match String(property):
		"position_jitter_x": return _position_jitter.x
		"position_jitter_y": return _position_jitter.y
		"position_jitter_z": return _position_jitter.z
	return null


func _set(property: StringName, value: Variant) -> bool:
	match String(property):
		"position_jitter_x":
			_position_jitter.x = maxf(0.0, value)
			_mark_dirty()
			return true
		"position_jitter_y":
			_position_jitter.y = maxf(0.0, value)
			_mark_dirty()
			return true
		"position_jitter_z":
			_position_jitter.z = maxf(0.0, value)
			_mark_dirty()
			return true
	return false


## Instance count excluding any position that would land on the template origin.
func get_instance_count() -> int:
	if pattern == null:
		return 0
	var ctx := {"template_size": Vector3.ONE, "rng": rng}
	var count := 0
	for position in pattern.generate(ctx):
		if not position.is_zero_approx():
			count += 1
	return count
