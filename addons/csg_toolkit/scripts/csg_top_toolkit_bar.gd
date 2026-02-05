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
		bake_btn.tooltip_text = "Bake generated instances into the scene (makes them persistent)"

func _exit_tree():
	EditorInterface.get_selection().selection_changed.disconnect(_on_selection_changed)

func _on_selection_changed():
	var selection = EditorInterface.get_selection().get_selected_nodes()
	if selection.is_empty():
		hide()
	elif selection[0] is CSGRepeater3D or selection[0] is CSGSpreader3D:
		show()
	else:
		hide()

func _on_refresh_pressed():
	var selection = EditorInterface.get_selection().get_selected_nodes()
	if (selection.is_empty()):
		return
	if selection[0] is CSGRepeater3D:
		selection[0].call("repeat_template")
	elif selection[0] is CSGSpreader3D:
		selection[0].call("spread_template")

func _on_bake_pressed():
	var selection = EditorInterface.get_selection().get_selected_nodes()
	if selection.is_empty():
		return
	if selection[0] is CSGRepeater3D or selection[0] is CSGSpreader3D:
		selection[0].call("bake_instances")
