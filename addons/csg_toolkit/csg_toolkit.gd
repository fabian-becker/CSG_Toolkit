@tool
class_name CsgToolkit extends EditorPlugin
@onready var config: CsgTkConfig:
	get:
		return get_tree().root.get_node_or_null(AUTOLOAD_NAME) as CsgTkConfig

var sidebar: CSGSideToolkitBar
var topbar: CSGTopToolkitBar
var shortcut_manager: CsgShortcutManager

const AUTOLOAD_NAME = "CsgToolkitAutoload"
static var csg_plugin_path
static var undo_manager: EditorUndoRedoManager

func _enter_tree():
	# Config
	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/csg_toolkit/scripts/csg_toolkit_config.gd")
	csg_plugin_path = get_path()
	undo_manager = get_undo_redo()
	
	# Nodes
	add_custom_type("CSGRepeater3D", "CSGCombiner3D", preload("res://addons/csg_toolkit/scripts/csg_repeater_3d.gd"), null)
	add_custom_type("CSGSpreader3D", "CSGCombiner3D", preload("res://addons/csg_toolkit/scripts/csg_spreader_3d.gd"), null)
	
	# Sidebar
	var sidebarScene = preload("res://addons/csg_toolkit/scenes/csg_side_toolkit_bar.tscn")
	sidebar = sidebarScene.instantiate()
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, sidebar)
	# Ensure sidebar can be found by shortcut manager if needed
	sidebar.add_to_group("CSGSideToolkit")
	
	# Topbar
	var topbarScene = preload("res://addons/csg_toolkit/scenes/csg_top_toolkit_bar.tscn")
	topbar = topbarScene.instantiate()
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, topbar)

	# Shortcut Manager
	shortcut_manager = CsgShortcutManager.new()
	get_tree().root.add_child(shortcut_manager)
	shortcut_manager.sidebar = sidebar

func _exit_tree():
	remove_custom_type("CSGRepeater3D")
	remove_custom_type("CSGSpreader3D")
	undo_manager = null
	
	remove_autoload_singleton(AUTOLOAD_NAME)
	
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT, sidebar)
	sidebar.free()
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, topbar)
	topbar.free()
	if shortcut_manager and is_instance_valid(shortcut_manager):
		shortcut_manager.queue_free()
