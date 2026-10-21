extends GutTest

const Repeater := preload("res://addons/csg_toolkit/scripts/csg_repeater_3d.gd")
const GridPattern := preload("res://addons/csg_toolkit/scripts/patterns/grid_pattern.gd")

func test_repeater_generates_instances_from_packed_scene_template():
	var repeater := Repeater.new()
	repeater.name = "Repeater"

	var template := Node3D.new()
	template.name = "Template"
	var scene := PackedScene.new()
	scene.pack(template)

	repeater.template_node_scene = scene
	repeater.pattern = GridPattern.new()
	repeater.pattern.count_x = 2
	repeater.pattern.count_y = 1
	repeater.pattern.count_z = 1
	repeater.pattern.use_template_size = false
	repeater.pattern.spacing = Vector3.ONE
	repeater.random_seed = 123
	repeater.rng = RandomNumberGenerator.new()

	# Bypass the editor _process loop and run generation directly.
	repeater.call("_run_generation")

	assert_eq(repeater.estimated_instances, 1, "origin position is filtered so only one instance remains")

	var generated_count := 0
	for child in repeater.get_children(true):
		if child.has_meta(Repeater.GENERATOR_NODE_META):
			generated_count += 1
			assert_true(child.transform.origin.is_equal_approx(Vector3.RIGHT),
				"single generated instance sits at the spacing offset")

	assert_eq(generated_count, 1)

	autofree(repeater)
	autofree(template)

func test_repeater_instance_count_excludes_origin():
	var repeater := Repeater.new()
	repeater.pattern = GridPattern.new()
	repeater.pattern.count_x = 2
	repeater.pattern.use_template_size = false
	repeater.pattern.spacing = Vector3.ONE

	assert_eq(repeater.get_instance_count(), 1, "only the non-origin position counts")

	autofree(repeater)
