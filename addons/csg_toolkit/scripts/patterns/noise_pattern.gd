@tool
class_name CSGNoisePattern
extends CSGPattern

## Generates instance positions based on noise sampling in a 3D volume
## Instances are placed where noise value exceeds the threshold

## 
@export var bounds: Vector3 = Vector3(10, 10, 10)

## 
@export var sample_density: Vector3i = Vector3i(20, 1, 20)

## 
@export_range(0.0, 1.0) var noise_threshold: float = 0.5

## 
@export var noise_seed: int = 0

##
@export_range(0.01, 100) var noise_frequency: float = 0.1

## 
@export_enum("Simplex", "Simplex Smooth", "Cellular", "Perlin", "Value Cubic", "Value") var noise_type: int = 0

##
@export_enum("None", "OpenSimplex2", "OpenSimplex2S", "Cellular", "Perlin", "Value Cubic", "Value") var fractal_type: int = 0

##
@export_range(1, 8) var fractal_octaves: int = 3

## 
@export var use_template_size: bool = false

var noise: FastNoiseLite

func _init():
	noise = FastNoiseLite.new()
	_update_noise()

func _update_noise():
	if not noise:
		noise = FastNoiseLite.new()
	
	noise.seed = noise_seed
	noise.frequency = noise_frequency
	noise.fractal_octaves = fractal_octaves
	
	# Map noise_type enum to FastNoiseLite types
	match noise_type:
		0: noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
		1: noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		2: noise.noise_type = FastNoiseLite.TYPE_CELLULAR
		3: noise.noise_type = FastNoiseLite.TYPE_PERLIN
		4: noise.noise_type = FastNoiseLite.TYPE_VALUE_CUBIC
		5: noise.noise_type = FastNoiseLite.TYPE_VALUE
	
	# Map fractal_type enum to FastNoiseLite fractal types
	match fractal_type:
		0: noise.fractal_type = FastNoiseLite.FRACTAL_NONE
		1: noise.fractal_type = FastNoiseLite.FRACTAL_FBM
		2: noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
		3: noise.fractal_type = FastNoiseLite.FRACTAL_PING_PONG

func _generate(ctx: Dictionary) -> Array:
	_update_noise()
	
	var positions: Array = []
	var template_size: Vector3 = ctx.get("template_size", Vector3.ONE) if use_template_size else Vector3.ZERO
	var jitter: float = ctx.get("position_jitter", 0.0)
	var rng: RandomNumberGenerator = ctx.get("rng", RandomNumberGenerator.new())
	
	var effective_bounds = bounds
	var sample_count = sample_density
	
	# Calculate step size for sampling
	var step = Vector3(
		effective_bounds.x / max(1, sample_count.x),
		effective_bounds.y / max(1, sample_count.y),
		effective_bounds.z / max(1, sample_count.z)
	)
	
	# Start from negative half to center the pattern around origin
	var start_pos = -effective_bounds * 0.5
	
	# Sample noise at regular intervals
	for x in range(sample_count.x):
		for y in range(sample_count.y):
			for z in range(sample_count.z):
				var sample_pos = start_pos + Vector3(
					x * step.x + step.x * 0.5,
					y * step.y + step.y * 0.5,
					z * step.z + step.z * 0.5
				)
				
				# Get noise value at this position (normalized to 0-1)
				var noise_value = (noise.get_noise_3d(sample_pos.x, sample_pos.y, sample_pos.z) + 1.0) * 0.5
				
				# Only place instance if noise exceeds threshold
				if noise_value >= noise_threshold:
					var final_pos = sample_pos
					
					# Apply template size offset if enabled
					if use_template_size:
						final_pos += template_size * Vector3(x, y, z)
					
					# Apply jitter
					if jitter > 0.0:
						final_pos += Vector3(
							rng.randf_range(-jitter, jitter),
							rng.randf_range(-jitter, jitter),
							rng.randf_range(-jitter, jitter)
						)
					
					positions.append(final_pos)
	
	return positions

func get_estimated_count(ctx: Dictionary) -> int:
	# Rough estimate: total samples * (1 - threshold)
	# Higher threshold = fewer instances
	var total_samples = max(1, sample_density.x) * max(1, sample_density.y) * max(1, sample_density.z)
	var estimated = int(total_samples * (1.0 - noise_threshold))
	return max(1, estimated)
