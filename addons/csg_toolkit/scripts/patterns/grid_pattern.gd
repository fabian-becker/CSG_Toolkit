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
	var jitter: float = ctx.get("position_jitter", 0.0)
	var rng: RandomNumberGenerator = ctx.get("rng", null)
	var cx: int = max(1, count_x)
	var cy: int = max(1, count_y)
	var cz: int = max(1, count_z)
	var base_step: Vector3 = (template_size if use_template_size else Vector3.ZERO) + spacing
	for x in range(cx):
		for y in range(cy):
			for z in range(cz):
				var position := Vector3(x * base_step.x, y * base_step.y, z * base_step.z)
				if jitter > 0.0 and rng != null:
					position += Vector3(
						rng.randf_range(-jitter, jitter),
						rng.randf_range(-jitter, jitter),
						rng.randf_range(-jitter, jitter)
					)
				positions.append(position)
	return positions


func get_estimated_count(_ctx: Dictionary) -> int:
	return max(1, count_x) * max(1, count_y) * max(1, count_z)