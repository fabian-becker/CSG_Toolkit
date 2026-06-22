@tool
@abstract class_name CSGPattern
extends Resource

## Base pattern interface. Subclasses implement _generate(ctx) returning Array[Vector3].
##
## ctx Dictionary keys:
##   template_size: Vector3 — AABB size of the template node (used for spacing)
##   rng: RandomNumberGenerator — seeded RNG shared with the repeater
##   position_jitter: float — per-axis random offset range (0 = no jitter)


## Generate all instance positions. Must be overridden by subclasses.
@abstract func _generate(ctx: Dictionary) -> Array[Vector3]


## Return the estimated number of instances that _generate() will produce.
## Used by the repeater for the MAX_INSTANCES cap check before generation.
## Must be overridden by subclasses for accuracy and performance.
@abstract func get_estimated_count(ctx: Dictionary) -> int


## Public entry point called by the repeater.
func generate(ctx: Dictionary) -> Array[Vector3]:
	return _generate(ctx)