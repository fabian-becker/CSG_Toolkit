@tool
class_name CSGNoisePattern
extends CSGPattern

## Generates instance positions based on noise sampling in a 3D volume.
## Instances are placed where noise value exceeds the threshold.

## Size of the sampling volume (before template_size scaling if enabled).
@export var bounds: Vector3 = Vector3(10, 10, 10)

## Grid resolution for noise sampling.
@export var sample_density: Vector3i = Vector3i(20, 1, 20)

## Instances are placed where noise >= this threshold (0–1).
@export_range(0.0, 1.0) var noise_threshold: float = 0.5

## Explicit noise seed. If 0, the repeater's random_seed is used instead.
@export var noise_seed: int = 0

@export_range(0.01, 100) var noise_frequency: float = 0.1

@export_enum("Simplex", "Simplex Smooth", "Cellular", "Perlin", "Value Cubic", "Value")
var noise_type: int = 0

@export_enum("None", "OpenSimplex2", "OpenSimplex2S", "Cellular", "Perlin", "Value Cubic", "Value")
var fractal_type: int = 0

@export_range(1, 8) var fractal_octaves: int = 3

## If true, bounds are multiplied by template_size so the volume scales with the template.
@export var use_template_size: bool = false

var noise: FastNoiseLite


func _init() -> void:
	noise = FastNoiseLite.new()
	_update_noise()


func _update_noise(seed_override: int = -1) -> void:
	if not noise:
		noise = FastNoiseLite.new()

	noise.seed = seed_override if seed_override >= 0 else noise_seed
	noise.frequency = noise_frequency
	noise.fractal_octaves = fractal_octaves

	# Map noise_type enum to FastNoiseLite types
	match noise_type:
		0:
			noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
		1:
			noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		2:
			noise.noise_type = FastNoiseLite.TYPE_CELLULAR
		3:
			noise.noise_type = FastNoiseLite.TYPE_PERLIN
		4:
			noise.noise_type = FastNoiseLite.TYPE_VALUE_CUBIC
		5:
			noise.noise_type = FastNoiseLite.TYPE_VALUE

	# Map fractal_type enum to FastNoiseLite fractal types
	match fractal_type:
		0:
			noise.fractal_type = FastNoiseLite.FRACTAL_NONE
		1:
			noise.fractal_type = FastNoiseLite.FRACTAL_FBM
		2:
			noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
		3:
			noise.fractal_type = FastNoiseLite.FRACTAL_PING_PONG


func _generate(ctx: Dictionary) -> Array[Vector3]:
	var positions: Array[Vector3] = []
	var template_size: Vector3 = ctx.get("template_size", Vector3.ONE)
	var jitter: float = ctx.get("position_jitter", 0.0)
	var rng: RandomNumberGenerator = ctx.get("rng", RandomNumberGenerator.new())
	var max_instances: int = ctx.get("max_instances", 50000)

	# Sync noise seed with the repeater's seed unless an explicit noise_seed is set.
	var effective_seed: int = noise_seed if noise_seed != 0 else rng.seed
	_update_noise(effective_seed)

	# Scale bounds by template_size when enabled (volume grows with template).
	var effective_bounds: Vector3 = bounds * template_size if use_template_size else bounds
	var sample_count: Vector3i = sample_density

	# Calculate step size for sampling
	var step := Vector3(
		effective_bounds.x / max(1, sample_count.x),
		effective_bounds.y / max(1, sample_count.y),
		effective_bounds.z / max(1, sample_count.z)
	)

	# Start from negative half to center the pattern around origin
	var start_pos := -effective_bounds * 0.5

	# Sample noise at regular intervals
	for x in range(sample_count.x):
		for y in range(sample_count.y):
			for z in range(sample_count.z):
				var sample_pos := (
					start_pos
					+ Vector3(
						x * step.x + step.x * 0.5,
						y * step.y + step.y * 0.5,
						z * step.z + step.z * 0.5
					)
				)

				# Get noise value at this position (normalized to 0-1)
				var noise_value: float = (
					(noise.get_noise_3d(sample_pos.x, sample_pos.y, sample_pos.z) + 1.0) * 0.5
				)

				# Only place instance if noise exceeds threshold
				if noise_value >= noise_threshold:
					var final_pos := sample_pos

					# Apply jitter
					if jitter > 0.0:
						final_pos += Vector3(
							rng.randf_range(-jitter, jitter),
							rng.randf_range(-jitter, jitter),
							rng.randf_range(-jitter, jitter)
						)

					positions.append(final_pos)

					# Hard cap: stop generating if we exceed the instance limit.
					if positions.size() >= max_instances:
						return positions

	return positions


func get_estimated_count(_ctx: Dictionary) -> int:
	# Upper bound: you can never have more instances than samples.
	# This is used for the MAX_INSTANCES cap check — using total_samples
	# as a safe upper bound ensures we abort when the grid is too dense,
	# rather than underestimating and generating unbounded instances.
	var total_samples: int = (
		max(1, sample_density.x) * max(1, sample_density.y) * max(1, sample_density.z)
	)
	return total_samples