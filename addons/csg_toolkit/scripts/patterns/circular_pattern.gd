@tool
class_name CSGCircularPattern
extends CSGPattern

@export var radius: float = 5.0
@export var points: int = 8
@export var layers: int = 1
## If 0 use template_size.y
@export var layer_height: float = 0.0
## Additional gap added per layer beyond base height
@export var layer_spacing: float = 0.0


func _generate(ctx: Dictionary) -> Array[Vector3]:
	var positions: Array[Vector3] = []
	var template_size: Vector3 = ctx.get("template_size", Vector3.ONE)
	var jitter: float = ctx.get("position_jitter", 0.0)
	var rng: RandomNumberGenerator = ctx.get("rng", null)
	var rad: float = max(0.0, radius)
	var count: int = max(1, points)
	if count <= 1:
		return [Vector3.ZERO]
	var lyr_count: int = max(1, layers)
	var base_y: float = layer_height if layer_height > 0.0 else template_size.y
	var step_y: float = base_y + max(0.0, layer_spacing)
	for i in range(count):
		var angle: float = (i * TAU) / count
		var base_pos := Vector3(cos(angle) * rad, 0, sin(angle) * rad)
		for layer in range(lyr_count):
			var position := base_pos + Vector3(0, layer * step_y, 0)
			if jitter > 0.0 and rng != null:
				position += Vector3(
					rng.randf_range(-jitter, jitter),
					rng.randf_range(-jitter, jitter),
					rng.randf_range(-jitter, jitter)
				)
			positions.append(position)
	return positions


func get_estimated_count(_ctx: Dictionary) -> int:
	return max(1, points) * max(1, layers)