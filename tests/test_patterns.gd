extends GutTest

const GridPattern := preload("res://addons/csg_toolkit/scripts/patterns/grid_pattern.gd")
const CircularPattern := preload("res://addons/csg_toolkit/scripts/patterns/circular_pattern.gd")
const SpiralPattern := preload("res://addons/csg_toolkit/scripts/patterns/spiral_pattern.gd")
const NoisePattern := preload("res://addons/csg_toolkit/scripts/patterns/noise_pattern.gd")

func test_grid_pattern_generates_expected_positions():
	var pattern := GridPattern.new()
	pattern.count_x = 2
	pattern.count_y = 1
	pattern.count_z = 1
	pattern.spacing = Vector3(1, 0, 0)
	pattern.use_template_size = true

	var ctx := {"template_size": Vector3(2, 1, 1)}
	var positions := pattern.generate(ctx)

	assert_eq(positions.size(), 2, "2x1x1 grid should produce two positions")
	assert_true(positions[0].is_equal_approx(Vector3.ZERO), "first grid position is the origin")
	assert_true(positions[1].is_equal_approx(Vector3(3, 0, 0)), "second position includes template size + spacing")
	assert_eq(pattern.get_estimated_count(ctx), 2, "estimate matches generated count")


func test_circular_pattern_generates_points_on_circle():
	var pattern := CircularPattern.new()
	pattern.radius = 1.0
	pattern.points = 4
	pattern.layers = 1
	pattern.layer_height = 1.0

	var ctx := {"template_size": Vector3.ONE}
	var positions := pattern.generate(ctx)

	assert_eq(positions.size(), 4)
	assert_eq(pattern.get_estimated_count(ctx), 4)
	assert_true(positions[0].is_equal_approx(Vector3(1, 0, 0)))
	assert_true(positions[1].is_equal_approx(Vector3(0, 0, 1)))
	assert_true(positions[2].is_equal_approx(Vector3(-1, 0, 0)))
	assert_true(positions[3].is_equal_approx(Vector3(0, 0, -1)))


func test_spiral_pattern_generates_arc_with_height():
	var pattern := SpiralPattern.new()
	pattern.turns = 1.0
	pattern.start_radius = 0.0
	pattern.end_radius = 1.0
	pattern.total_height = 2.0
	pattern.points = 3

	var ctx := {"template_size": Vector3.ONE}
	var positions := pattern.generate(ctx)

	assert_eq(positions.size(), 3)
	assert_eq(pattern.get_estimated_count(ctx), 3)
	assert_true(positions[0].is_equal_approx(Vector3.ZERO))
	assert_true(positions[1].is_equal_approx(Vector3(-0.5, 1, 0)))
	assert_true(positions[2].is_equal_approx(Vector3(1, 2, 0)))


func test_noise_pattern_returns_bounded_positions():
	var pattern := NoisePattern.new()
	pattern.noise_seed = 42
	pattern.sample_density = Vector3i(2, 1, 2)
	pattern.bounds = Vector3(4, 2, 4)
	pattern.noise_threshold = 0.0  # accept every sample for a deterministic upper bound

	var ctx := {"template_size": Vector3.ONE, "rng": RandomNumberGenerator.new()}
	var positions := pattern.generate(ctx)

	assert_eq(positions.size(), 4, "threshold 0 keeps all samples")
	assert_eq(pattern.get_estimated_count(ctx), 4)
	for p in positions:
		assert_true(p.x >= -2.0 and p.x <= 2.0, "x inside bounds")
		assert_true(p.z >= -2.0 and p.z <= 2.0, "z inside bounds")
