@tool
class_name CSGSpiralPattern
extends CSGPattern

@export var turns: float = 2.0
@export var start_radius: float = 0.5
@export var end_radius: float = 5.0
## Vertical spread of the spiral. 0 = flat (all points at y = 0).
@export var total_height: float = 0.0
## If true, the template's measured Y size is used as the vertical spread
## (total_height is ignored). The old implicit fallback, now opt-in.
@export var use_template_height: bool = false
@export var use_radius_curve: bool = false
@export var radius_curve: Curve
@export var points: int = 32


func _generate(ctx: Dictionary) -> Array[Vector3]:
	var positions: Array[Vector3] = []
	var template_size: Vector3 = ctx.get("template_size", Vector3.ONE)
	var t_turns: float = max(0.1, turns)
	var r_start: float = max(0.0, start_radius)
	var r_end: float = max(r_start, end_radius)
	var height: float = (template_size.y if use_template_height else max(0.0, total_height))
	var total: int = max(2, points)
	if total <= 1:
		return [Vector3.ZERO]
	for i in range(total):
		var t: float = float(i) / float(total - 1)
		var angle: float = t * t_turns * TAU
		var curve_t: float = t
		if use_radius_curve and radius_curve and radius_curve.get_point_count() > 0:
			curve_t = clamp(radius_curve.sample(t), 0.0, 1.0)
		# Position jitter (per-axis) is applied by the repeater's variation
		# system so every pattern type gets it.
		var radius: float = lerp(r_start, r_end, curve_t)
		positions.append(Vector3(
			cos(angle) * radius,
			t * height,
			sin(angle) * radius
		))
	return positions


func get_estimated_count(_ctx: Dictionary) -> int:
	return max(2, points)