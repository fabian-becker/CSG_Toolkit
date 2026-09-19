@tool
class_name CSGTopToolkitBar extends Control

func _enter_tree():
	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)
	_on_selection_changed()
	# Attempt to find buttons and add tooltips if present
	var refresh_btn = find_child("Refresh", true, false)
	if refresh_btn and refresh_btn is Button:
		refresh_btn.tooltip_text = "Regenerate preview instances"
	var bake_btn = find_child("Bake", true, false)
	if bake_btn and bake_btn is Button:
		bake_btn.tooltip_text = "Bake generated instances into the scene (undoable; makes them persistent)"
	var freeze_btn = find_child("Freeze", true, false)
	if freeze_btn and freeze_btn is Button:
		freeze_btn.tooltip_text = "Freeze preview to a single baked mesh (fast for large generations) or restore live CSG instances"

func _exit_tree():
	EditorInterface.get_selection().selection_changed.disconnect(_on_selection_changed)

func _on_selection_changed():
	var selection = EditorInterface.get_selection().get_selected_nodes()
	if selection.is_empty():
		hide()
		return
	var generator := selection[0] as CsgGeneratorBase
	if generator == null:
		hide()
		return
	show()
	var freeze_btn = find_child("Freeze", true, false)
	if freeze_btn and freeze_btn is Button:
		(freeze_btn as Button).button_pressed = generator._frozen

func _on_refresh_pressed():
	var selection = EditorInterface.get_selection().get_selected_nodes()
	if selection.is_empty():
		return
	if selection[0] is CsgGeneratorBase:
		selection[0].refresh()

func _on_bake_pressed():
	var selection = EditorInterface.get_selection().get_selected_nodes()
	if selection.is_empty():
		return
	if selection[0] is CsgGeneratorBase:
		selection[0].bake_instances()

func _on_freeze_pressed():
	var selection = EditorInterface.get_selection().get_selected_nodes()
	if selection.is_empty():
		return
	var generator := selection[0] as CsgGeneratorBase
	if generator == null:
		return
	if generator._frozen:
		generator.unfreeze()
	else:
		generator._apply_freeze()
	var freeze_btn = find_child("Freeze", true, false)
	if freeze_btn and freeze_btn is Button:
		(freeze_btn as Button).button_pressed = generator._frozen
