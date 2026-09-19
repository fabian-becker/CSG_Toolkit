@tool
class_name CSGGridPattern
extends CSGPattern

@export var count_x: int = 2
@export var count_y: int = 1
@export var count_z: int = 1
@export var spacing: Vector3 = Vector3.ZERO

## If true, automatically adds template AABB size to spacing for proper object separation
@export var use_template_size: bool = true


func _generate(ctx: Dictionary) -> Array[Vector3]:
	var positions: Array[Vector3] = []
	var template_size: Vector3 = ctx.get("template_size", Vector3.ONE)
	var rng: RandomNumberGenerator = ctx.get("rng", null)
	var cx: int = max(1, count_x)
	var cy: int = max(1, count_y)
	var cz: int = max(1, count_z)
	var base_step: Vector3 = (template_size if use_template_size else Vector3.ZERO) + spacing
	for x in range(cx):
		for y in range(cy):
			for z in range(cz):
				# Position jitter (per-axis) is applied by the repeater's
				# variation system so every pattern type gets it.
				positions.append(Vector3(x * base_step.x, y * base_step.y, z * base_step.z))
	return positions


func get_estimated_count(_ctx: Dictionary) -> int:
	return max(1, count_x) * max(1, count_y) * max(1, count_z)