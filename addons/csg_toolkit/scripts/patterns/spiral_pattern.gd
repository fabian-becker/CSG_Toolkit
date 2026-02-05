@tool
class_name CSGSpiralPattern
extends CSGPattern

@export var turns: float = 2.0
@export var start_radius: float = 0.5
@export var end_radius: float = 5.0
## If > 0 overrides vertical spread based on repeat & step
@export var total_height: float = 0.0
@export var use_radius_curve: bool = false
@export var radius_curve: Curve
@export var points: int = 32

func _generate(ctx: Dictionary) -> Array:
	var positions: Array = []
	var template_size: Vector3 = ctx.get("template_size", Vector3.ONE)
	var t_turns: float = max(0.1, turns)
	var r_start: float = max(0.0, start_radius)
	var r_end: float = max(r_start, end_radius)
	var total: int = max(2, points)
	if total <= 1:
		return [Vector3.ZERO]
	for i in range(total):
		var t: float = float(i) / float(total - 1)
		var angle = t * t_turns * TAU
		var curve_t = t
		if use_radius_curve and radius_curve and radius_curve.get_point_count() > 0:
			curve_t = clamp(radius_curve.sample(t), 0.0, 1.0)
		var radius = lerp(r_start, r_end, curve_t)
		var y_pos: float = t * (total_height if total_height > 0.0 else template_size.y * 1.0)
		positions.append(Vector3(
			cos(angle) * radius,
			y_pos,
			sin(angle) * radius
		))
	return positions

func get_estimated_count(ctx: Dictionary) -> int:
	return max(2, points)
