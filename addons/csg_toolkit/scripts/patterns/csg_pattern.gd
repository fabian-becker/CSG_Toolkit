@tool
@abstract
class_name CSGPattern
extends Resource

## Base pattern interface. Subclasses implement _generate(RepeaterContext) returning Array[Vector3].

# Common interface call
func generate(ctx: Dictionary) -> Array:
	# ctx expected keys: repeat: Vector3i, spacing: Vector3, rng: RandomNumberGenerator, step_spacing: Vector3, user: Node (repeater)
	return _generate(ctx)

func _generate(_ctx: Dictionary) -> Array:
	return []

func get_estimated_count(ctx: Dictionary) -> int:
	# Default: fallback to generating (may be overridden for performance/accuracy)
	var arr = _generate(ctx)
	return arr.size()
