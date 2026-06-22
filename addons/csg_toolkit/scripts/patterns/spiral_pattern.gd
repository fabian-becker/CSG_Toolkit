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


func _generate(ctx: Dictionary) -> Array[Vector3]:
	var positions: Array[Vector3] = []
	var template_size: Vector3 = ctx.get("template_size", Vector3.ONE)
	var jitter: float = ctx.get("position_jitter", 0.0)
	var rng: RandomNumberGenerator = ctx.get("rng", null)
	var t_turns: float = max(0.1, turns)
	var r_start: float = max(0.0, start_radius)
	var r_end: float = max(r_start, end_radius)
	var total: int = max(2, points)
	if total <= 1:
		return [Vector3.ZERO]
	for i in range(total):
		var t: float = float(i) / float(total - 1)
		var angle: float = t * t_turns * TAU
		var curve_t: float = t
		if use_radius_curve and radius_curve and radius_curve.get_point_count() > 0:
			curve_t = clamp(radius_curve.sample(t), 0.0, 1.0)
		var r: float = lerp(r_start, r_end, curve_t)
		var y_pos: float = t * (total_height if total_height > 0.0 else template_size.y * 1.0)
		var position := Vector3(cos(angle) * r, y_pos, sin(angle) * r)
		if jitter > 0.0 and rng != null:
			position += Vector3(
				rng.randf_range(-jitter, jitter),
				rng.randf_range(-jitter, jitter),
				rng.randf_range(-jitter, jitter)
			)
		positions.append(position)
	return positions


func get_estimated_count(_ctx: Dictionary) -> int:
	return max(2, points)