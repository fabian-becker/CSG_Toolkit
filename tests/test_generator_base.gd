extends GutTest

const GeneratorBase := preload("res://addons/csg_toolkit/scripts/csg_generator_base.gd")

func test_unique_bake_container_name_avoids_collisions():
	var root := Node3D.new()
	var generator := GeneratorBase.new()
	generator.name = "Gen"

	var existing := Node3D.new()
	existing.name = "Baked_Gen"
	root.add_child(existing)
	root.add_child(generator)

	var next_name: String = generator.call("_unique_bake_container_name", root)
	assert_eq(next_name, "Baked_Gen_2", "name collision should append a counter")

	autofree(root)
	autofree(generator)
	autofree(existing)


func test_template_size_measures_visual_aabb():
	var generator := GeneratorBase.new()
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2, 3, 4)
	mesh_instance.mesh = box

	var size: Vector3 = generator.call("_get_template_size", mesh_instance)
	assert_true(size.is_equal_approx(Vector3(2, 3, 4)), "template size equals box mesh size")

	autofree(generator)
	autofree(mesh_instance)
	box = null


func test_make_instance_tags_meta_and_position():
	var generator := GeneratorBase.new()
	var template := Node3D.new()
	template.visible = false

	var instance: Node = generator.call("_make_instance", template, Vector3(1, 2, 3))
	assert_true(instance.get_meta(GeneratorBase.GENERATOR_NODE_META), "instance carries generator meta")
	assert_true(instance.visible, "generated instance is visible even if template is hidden")
	assert_true(instance.transform.origin.is_equal_approx(Vector3(1, 2, 3)))

	autofree(generator)
	autofree(template)
	autofree(instance)


func test_is_instance_copy_reads_meta():
	var generator := GeneratorBase.new()
	assert_false(generator.call("_is_instance_copy"), "fresh generator is not a copy")

	generator.set_meta(GeneratorBase.BAKED_NODE_META, true)
	assert_true(generator.call("_is_instance_copy"), "baked-meta marks node as copy")

	autofree(generator)
