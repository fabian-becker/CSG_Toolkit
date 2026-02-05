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

func _generate(ctx: Dictionary) -> Array:
	var positions: Array = []
	var template_size: Vector3 = ctx.get("template_size", Vector3.ONE)
	var rad: float = max(0.0, radius)
	var count: int = max(1, points)
	if count <= 1:
		return [Vector3.ZERO]
	var lyr_count = max(1, layers)
	var base_y = layer_height if layer_height > 0.0 else template_size.y
	var step_y = base_y + max(0.0, layer_spacing)
	for i in range(count):
		var angle = (i * TAU) / count
		var base_pos = Vector3(cos(angle) * rad, 0, sin(angle) * rad)
		for layer in range(lyr_count):
			positions.append(base_pos + Vector3(0, layer * step_y, 0))
	return positions

func get_estimated_count(ctx: Dictionary) -> int:
	return max(1, points) * max(1, layers)
