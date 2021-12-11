tool

extends EditorPlugin

var gizmo_plugin := DirectionSwitchGizmo.new()

func _enter_tree():
	add_spatial_gizmo_plugin(gizmo_plugin)
	gizmo_plugin.undo_redo = get_undo_redo()


func _exit_tree():
	remove_spatial_gizmo_plugin(gizmo_plugin)
