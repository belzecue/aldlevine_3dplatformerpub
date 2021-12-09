extends EditorSpatialGizmoPlugin

class_name MovePlaneGizmo

var undo_redo : UndoRedo

func _init() -> void:
	create_material("plane", Color(1, 0, 0))
	create_handle_material("handle")

func get_name() -> String:
	return "MovePlaneGizmo"

func has_gizmo(spatial: Spatial) -> bool:
	return spatial is MovePlane

func redraw(gizmo: EditorSpatialGizmo) -> void:
	gizmo.clear()

	var move_plane := gizmo.get_spatial_node() as MovePlane

	var corners := get_corners(move_plane)
	gizmo.add_handles(corners, get_material("handle", gizmo))

	corners.resize(4)
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = corners
	arrays[ArrayMesh.ARRAY_INDEX] = PoolIntArray([0, 1, 2, 2, 3, 0])
	arrays[ArrayMesh.ARRAY_TEX_UV] = PoolVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	gizmo.add_mesh(mesh, false, null, preload("MovePlaneMaterial.tres"))

	var pick_segments := PoolVector3Array()
	for i in corners.size():
		pick_segments.push_back(corners[i])
		pick_segments.push_back(corners[(i + 1) % corners.size()])
	gizmo.add_collision_segments(pick_segments)


func get_corners(move_plane: MovePlane) -> PoolVector3Array:
	var res := PoolVector3Array()
	res.push_back((Vector3(move_plane.bottom_left.x, move_plane.bottom_left.y, 0.0)))
	res.push_back((Vector3(move_plane.bottom_right.x, move_plane.bottom_right.y, 0.0)))
	res.push_back((Vector3(move_plane.top_right.x, move_plane.top_right.y, 0.0)))
	res.push_back((Vector3(move_plane.top_left.x, move_plane.top_left.y, 0.0)))

	var bottom = move_plane.bottom
	var left = move_plane.left
	var top = move_plane.top
	var right = move_plane.right
	res.push_back((Vector3(bottom.x, bottom.y, 0.0)))
	res.push_back((Vector3(left.x, left.y, 0.0)))
	res.push_back((Vector3(top.x, top.y, 0.0)))
	res.push_back((Vector3(right.x, right.y, 0.0)))
	return res

func get_handle_name(gizmo: EditorSpatialGizmo, index: int) -> String:
	return ["bottom_left", "bottom_right", "top_right", "top_left", "bottom", "left", "top", "right"][index]

func set_handle(gizmo: EditorSpatialGizmo, index: int, camera: Camera, point: Vector2) -> void:
	var move_plane := gizmo.get_spatial_node() as MovePlane
	var handle_name := get_handle_name(gizmo, index)
	var normal := camera.project_ray_normal(point)
	var origin := camera.project_ray_origin(point)
	# var plane := Plane(move_plane.global_transform.basis.xform(Vector3.FORWARD), 0)

	# var bottom_left = move_plane.global_transform.xform(Vector3(move_plane.bottom_left.x, move_plane.bottom_left.y, 0))
	# var bottom_right = move_plane.global_transform.xform(Vector3(move_plane.bottom_right.x, move_plane.bottom_right.y, 0))
	# var top_right = move_plane.global_transform.xform(Vector3(move_plane.top_right.x, move_plane.top_right.y, 0))
	# var plane := Plane(bottom_left, bottom_right, top_right)
	var plane := move_plane.get_plane()
	var handle_new_world := plane.intersects_ray(origin, normal)
	var handle_new = move_plane.global_transform.affine_inverse().xform(handle_new_world)
	handle_new = handle_new.snapped(Vector3(1, 1, 1))
	move_plane.set(handle_name, Vector2(handle_new.x, handle_new.y))
	redraw(gizmo)

func get_handle_value(gizmo: EditorSpatialGizmo, index: int) -> Vector2:
	var move_plane := gizmo.get_spatial_node() as MovePlane
	var handle_name := get_handle_name(gizmo, index)
	return move_plane.get(handle_name) as Vector2

func commit_handle(gizmo: EditorSpatialGizmo, index: int, restore, cancel: bool = false) -> void:
	var move_plane := gizmo.get_spatial_node() as MovePlane
	var handle_name := get_handle_name(gizmo, index)
	if cancel:
		move_plane.set(handle_name, restore)
	else:
		var value := move_plane.get(handle_name) as Vector2
		undo_redo.create_action("set " + handle_name)
		undo_redo.add_undo_property(move_plane, handle_name, restore)
		undo_redo.add_undo_method(self, "redraw", gizmo)
		undo_redo.add_do_property(move_plane, handle_name, value)
		undo_redo.commit_action()
	redraw(gizmo)