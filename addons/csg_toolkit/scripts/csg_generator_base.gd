@tool
class_name CsgGeneratorBase
extends CSGCombiner3D

## Shared base for CSGRepeater3D and CSGSpreader3D.
## Owns the dirty/generation loop, stale-instance clearing, template
## resolution, instance bookkeeping (meta tagging), AABB measurement, and
## undo-aware baking. Subclasses only implement placement (_generate_instances)
## and variations.

const GENERATOR_NODE_META := "CSG_GENERATOR_INSTANCE_META"
const FROZEN_PREVIEW_META := "CSG_TOOLKIT_FROZEN_PREVIEW"
const MAX_INSTANCES := 20000

## While a property is being dragged, new marks keep resetting this timer so
## the node only rebuilds once input settles -- instead of one full CSG bake
## per frame.
const REGEN_DEBOUNCE_MS := 250

var _dirty: bool = false
var _dirty_at_ms: int = 0
var _generation_in_progress := false
var _pending_template_instance: Node = null
var rng: RandomNumberGenerator

## Freeze-to-mesh preview state. When frozen, all generated CSG children are
## replaced by ONE MeshInstance3D of the combiner's last bake: no CSG children,
## no rebakes while the user orbits/selects/edits other properties.
var _frozen := false
var _freeze_pending := false
var _frozen_mesh: Mesh = null
var _frozen_transforms: Array = []

## Instance count of the last generation. Editor-only, read-only in the
## inspector, and intentionally NOT serialized into scenes.
var estimated_instances: int = 0

## Path to the template node used as the duplicate source.
@export var template_node_path: NodePath:
	get: return _template_node_path
	set(value):
		_template_node_path = value
		_mark_dirty()

var _template_node_path: NodePath

## Template scene fallback used when template_node_path does not resolve.
@export var template_node_scene: PackedScene:
	get: return _template_node_scene
	set(value):
		_template_node_scene = value
		_mark_dirty()

var _template_node_scene: PackedScene

## At or above this generated instance count the node auto-freezes into a
## single baked mesh. Set to 0 to disable auto-freezing.
@export var freeze_threshold: int = 200


func _ready():
	rng = RandomNumberGenerator.new()
	_setup_generator()
	_mark_dirty()


## Virtual: called once by _ready before the first dirty flush. Subclasses
## assign default resources here (e.g. a default pattern).
func _setup_generator() -> void:
	pass


## Template method: guards re-entry, clears the previous generation, then
## delegates placement to the subclass. Subclasses implement
## _generate_instances() and MUST NOT manage _generation_in_progress or call
## clear_children() themselves.
func _run_generation() -> void:
	if _generation_in_progress:
		return
	_generation_in_progress = true
	if _frozen:
		_unfreeze(false)
	clear_children()
	_generate_instances()
	_generation_in_progress = false
	if freeze_threshold > 0 and _count_meta_instances() >= freeze_threshold:
		# Capture one frame later, after the engine's deferred CSG bake has
		# produced the updated combiner mesh.
		_freeze_pending = true


## Virtual: performs the actual generation. Stale instances have already been
## removed; create new ones via _make_instance().
func _generate_instances() -> void:
	pass


func _process(_delta):
	if not Engine.is_editor_hint():
		return
	if _freeze_pending and not _dirty and not _generation_in_progress:
		_apply_freeze()
		return
	if _dirty and not _generation_in_progress:
		# Debounce: property drags re-mark every frame; only rebuild once the
		# input has settled for REGEN_DEBOUNCE_MS.
		if Time.get_ticks_msec() - _dirty_at_ms < REGEN_DEBOUNCE_MS:
			return
		_dirty = false
		call_deferred("_run_generation")


func _exit_tree():
	# Always clean up generated preview instances (both in editor and at runtime teardown).
	if _frozen:
		# Drop the stored instances and preview mesh without restoring.
		for entry in _frozen_transforms:
			var node: Node = entry["node"]
			if is_instance_valid(node):
				node.queue_free()
		_frozen_transforms.clear()
		_frozen_mesh = null
		_frozen = false
	clear_children()


func _mark_dirty():
	_dirty = true
	_dirty_at_ms = Time.get_ticks_msec()


## Explicit refresh (used by the top bar's Refresh button). Bypasses the
## debounce and rebuilds immediately on the next frame.
func refresh() -> void:
	_dirty = false
	_generation_in_progress = false
	call_deferred("_run_generation")


## Removes all generated instances (children tagged with GENERATOR_NODE_META).
## The template node itself is preserved.
func clear_children():
	var children_to_remove = []
	for child in get_children(true):
		if child.has_meta(GENERATOR_NODE_META):
			children_to_remove.append(child)
	for child in children_to_remove:
		remove_child(child)
		child.queue_free()


# -- Freeze-to-mesh preview ------------------------------------------------------------

## Replaces all generated CSG instances with a single MeshInstance3D showing
## the combiner's current baked mesh. Editor-only: massive perf win for large
## generations since the frozen node has no CSG children to rebake.
func _apply_freeze():
	_freeze_pending = false
	if _frozen:
		return
	# get_meshes() returns [Transform3D, Mesh]; index 1 is the root bake.
	# Only works on root shapes; empty otherwise (then we simply stay live).
	var meshes := get_meshes()
	var mesh: Mesh = meshes[1] if meshes.size() > 1 else null
	if mesh == null or mesh.get_faces().is_empty():
		return
	_unfreeze(false) # safety, should already be unfrozen
	var capture := MeshInstance3D.new()
	capture.name = "FrozenPreview"
	capture.mesh = mesh
	capture.set_meta(FROZEN_PREVIEW_META, true)
	# Store per-instance transforms so unfreeze can restore exact placements.
	_frozen_transforms.clear()
	for child in get_children(true):
		if child.has_meta(GENERATOR_NODE_META) and child is Node3D:
			_frozen_transforms.append({"node": child, "transform": (child as Node3D).transform})
	for entry in _frozen_transforms:
		var node: Node = entry["node"]
		if is_instance_valid(node):
			remove_child(node)
			# Not freed: unfreeze re-adds the same nodes with their transforms.
	add_child(capture)
	_frozen_mesh = mesh
	_frozen = true


## Restores the individual CSG instances from the frozen preview.
## regenerate: also triggers a fresh generation afterwards.
func _unfreeze(regenerate: bool):
	_freeze_pending = false
	if not _frozen:
		if regenerate:
			_mark_dirty()
		return
	for child in get_children(true):
		if child.has_meta(FROZEN_PREVIEW_META):
			remove_child(child)
			child.queue_free()
	for entry in _frozen_transforms:
		var node: Node = entry["node"]
		if is_instance_valid(node):
			add_child(node)
			(node as Node3D).transform = entry["transform"]
	_frozen_transforms.clear()
	_frozen_mesh = null
	_frozen = false
	if regenerate:
		_mark_dirty()


## Editor-facing unfreeze (e.g. from the top bar or inspector context).
func unfreeze():
	_unfreeze(true)


func _count_meta_instances() -> int:
	var count := 0
	for child in get_children(true):
		if child.has_meta(GENERATOR_NODE_META):
			count += 1
	return count


## Resolves the template: node path first, then the template scene.
## Scene instances are tracked so they can be released after generation.
func _get_template_node() -> Node:
	var node := get_node_or_null(template_node_path)
	if node:
		return node
	if template_node_scene and template_node_scene.can_instantiate():
		_pending_template_instance = template_node_scene.instantiate()
		add_child(_pending_template_instance)
		return _pending_template_instance
	return null


## Releases a temporarily added template scene instance (if any).
func _release_template_instance():
	if _pending_template_instance and is_instance_valid(_pending_template_instance):
		remove_child(_pending_template_instance)
		_pending_template_instance.queue_free()
	_pending_template_instance = null


## Duplicates the template and tags/positions it as a generated instance.
func _make_instance(template_node: Node, position: Vector3) -> Node:
	var instance = template_node.duplicate()
	if instance == null:
		return null
	instance.set_meta(GENERATOR_NODE_META, true)
	instance.transform.origin = position
	add_child(instance)
	return instance


## Bakes generated instances into the scene by assigning the scene owner,
## wrapped in the editor undo/redo history so it can be undone. Frozen previews
## are unfrozen first so the real CSG children get baked, not the proxy mesh.
func bake_instances():
	if _frozen:
		_unfreeze(false)
	var instances: Array = []
	for child in get_children(true):
		if child.has_meta(GENERATOR_NODE_META):
			instances.append(child)
	if instances.is_empty():
		return

	var scene_owner := owner
	var undo: EditorUndoRedoManager = CsgToolkit.undo_manager
	if undo:
		undo.create_action("Bake %s instances (%s)" % [instances.size(), get_class()])
		undo.add_do_method(self, "_bake_set_owners", instances, scene_owner)
		undo.add_undo_method(self, "_bake_clear_owners", instances)
		undo.commit_action()
	else:
		_bake_set_owners(instances, scene_owner)


func _bake_set_owners(instances: Array, scene_owner: Node) -> void:
	for node in instances:
		if is_instance_valid(node):
			node.owner = scene_owner


func _bake_clear_owners(instances: Array) -> void:
	for node in instances:
		if is_instance_valid(node):
			node.owner = null


## Backward-compatible alias for older tooling.
func apply_template():
	bake_instances()


# -- Geometry-based template size helpers -------------------------------------------

## Combined AABB of the template measured in the template's local space,
## with all child transforms applied (unlike a naive recursive merge).
func _get_template_size(template_node: Node) -> Vector3:
	if template_node == null or not (template_node is Node3D):
		return Vector3.ONE
	var aabb := _get_combined_aabb(template_node)
	var size: Vector3 = aabb.size
	if size.x <= 0.0001: size.x = 1.0
	if size.y <= 0.0001: size.y = 1.0
	if size.z <= 0.0001: size.z = 1.0
	return size


func _get_combined_aabb(root: Node) -> AABB:
	var found := false
	var combined := AABB()
	# Stack entries: [node, transform of that node relative to the root].
	var stack: Array = [[root, Transform3D.IDENTITY]]
	while not stack.is_empty():
		var entry: Array = stack.pop_back()
		var current: Node = entry[0]
		var parent_xform: Transform3D = entry[1]
		if current is Node3D:
			var local_xform: Transform3D = parent_xform * (current as Node3D).transform
			if current is VisualInstance3D:
				var world_aabb: AABB = local_xform * (current as VisualInstance3D).get_aabb()
				if world_aabb.size != Vector3.ZERO:
					if not found:
						combined = world_aabb
						found = true
					else:
						combined = combined.merge(world_aabb)
			for child in current.get_children():
				stack.append([child, local_xform])
	return combined if found else AABB(Vector3.ZERO, Vector3.ZERO)


# -- Shared variation helpers --------------------------------------------------------

## Random Y rotation (used by the spreader's simple variation mode).
func _apply_random_y_rotation(instance: Node3D) -> void:
	instance.rotate_y(rng.randf_range(0.0, TAU))


## Random uniform scale factor, clamped so instances never invert or vanish.
func _apply_random_scale(instance: Node3D, min_factor: float, max_factor: float) -> void:
	instance.scale *= clampf(rng.randf_range(min_factor, max_factor), 0.05, 10.0)


# -- Inspector -----------------------------------------------------------------------

## Estimated instance count without generating (pattern-aware in subclasses).
func get_instance_count() -> int:
	return 0


func _get_property_list() -> Array[Dictionary]:
	return [{
		"name": "estimated_instances",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY,
	}]