tool 

extends EditorSpatialGizmoPlugin

class_name DirectionSwitchGizmo

var undo_redo : UndoRedo
var circle_material := preload("GizmoCircle.material")

func _init() -> void:
	create_material("line", Color(1, 1, 1))
	create_handle_material("handle")

func get_name() -> String:
	return "Direction Switch"

func has_gizmo(spatial: Spatial) -> bool:
	return spatial is DirectionSwitch

func redraw(gizmo: EditorSpatialGizmo) -> void:
	gizmo.clear()

	var switch := gizmo.get_spatial_node() as DirectionSwitch

	gizmo.add_handles([
		switch.xform_a.origin,
		switch.xform_b.origin
		], get_material("handle", gizmo))

	# draw path
	var steps := 90
	var inc := 1.0 / steps
	for s in steps:
		var i = s * inc
		var start := switch.interpolate(i)
		var end := switch.interpolate(i + inc)
		gizmo.add_lines(PoolVector3Array([start.origin, end.origin]), get_material("line", gizmo), false, Color.red)
		gizmo.add_lines(PoolVector3Array([start.origin, start.origin + start.basis.z * 0.25]), get_material("line", gizmo), false, Color.red)
		if s == steps - 1:
			gizmo.add_lines(PoolVector3Array([end.origin, end.origin + end.basis.z * 0.25]), get_material("line", gizmo), false, Color.red)

	# draw base circle
	for i in 360:
		var r1 := deg2rad(i)
		var r2 := deg2rad(i + 1)
		var p1 := Vector3(sin(r1), 0, -cos(r1)) * switch.radius
		var p2 := Vector3(sin(r2), 0, -cos(r2)) * switch.radius
		gizmo.add_lines(PoolVector3Array([p1, p2]), circle_material, false, Color.green)

	# draw tilt circles
	for i in 360:
		var r1 := deg2rad(i)
		var r2 := deg2rad(i + 1)
		var p1 := Vector3(0, -cos(r1), sin(r1)) * 0.25
		var p2 := Vector3(0, -cos(r2), sin(r2)) * 0.25
		gizmo.add_lines(switch.xform_a.xform(PoolVector3Array([p1, p2])), circle_material, false, Color.red)
		gizmo.add_lines(switch.xform_b.xform(PoolVector3Array([p1, p2])), circle_material, false, Color.blue)

func get_handle_name(gizmo: EditorSpatialGizmo, index: int) -> String:
	return [
		"xform_a",
		"xform_b",
	][index]

func set_handle(gizmo: EditorSpatialGizmo, index: int, camera: Camera, point: Vector2) -> void:
	var switch := gizmo.get_spatial_node() as DirectionSwitch

	var ray_origin := camera.project_ray_origin(point)
	var ray_normal := camera.project_ray_normal(point)

	if index <= 1:
		if Input.is_key_pressed(KEY_CONTROL):
			# Radius
			var a := switch.global_transform * Vector3(-1, 0, 0)
			var b := switch.global_transform * Vector3(0.5, 0, 1)
			var c := switch.global_transform * Vector3(1, 0, 0)
			var plane := Plane(a, b, c)

			var isect := plane.intersects_ray(ray_origin, ray_normal)
			if !isect:
				return
			var isect_local : Vector3 = switch.global_transform.xform_inv(isect)
			switch.radius = stepify(isect_local.length(), 0.25)

		elif Input.is_key_pressed(KEY_SHIFT):
			# Tilt
			var xform := get_handle_value(gizmo, index)
			xform = xform.rotated(xform.basis.x, -xform.basis.get_euler().x)
			xform = xform.orthonormalized()

			var a := switch.global_transform * xform * Vector3(0, 0, -1)
			var b := switch.global_transform * xform * Vector3(0, 1, 0.5)
			var c := switch.global_transform * xform * Vector3(0, 0, 1)
			var plane := Plane(a, b, c)

			var isect := plane.intersects_ray(ray_origin, ray_normal)
			if !isect:
				return
			var isect_local : Vector3 = (switch.global_transform * xform).xform_inv(isect)

			var angle := isect_local.signed_angle_to(Vector3.BACK, Vector3.LEFT)
			angle = stepify(angle, PI / 8)
			xform.basis = xform.basis.rotated(xform.basis.x, angle)

			if index == 0:
				switch.xform_a = xform
			elif index == 1:
				switch.xform_b = xform
		else:
			# Horizontal
			var a := switch.global_transform * Vector3(-1, 0, 0)
			var b := switch.global_transform * Vector3(0.5, 0, 1)
			var c := switch.global_transform * Vector3(1, 0, 0)
			var plane := Plane(a, b, c)

			var isect := plane.intersects_ray(ray_origin, ray_normal)
			if !isect:
				return
			var isect_local : Vector3 = switch.global_transform.xform_inv(isect)

			var angle := isect_local.signed_angle_to(Vector3.RIGHT, Vector3.DOWN)
			angle = stepify(angle, PI / 8)


			var direction := Vector3.RIGHT.rotated(Vector3.UP, angle)
			var xform := get_handle_value(gizmo, index)
			var back := xform.basis.x.rotated(Vector3.UP, -PI / 2)
			var tilt := -xform.basis.z.signed_angle_to(back, xform.basis.x)

			xform = Transform()
			xform.origin = direction * switch.radius
			xform.basis = xform.basis.rotated(Vector3.UP, angle)
			xform.basis = xform.basis.rotated(xform.basis.x, tilt)
			if index == 0:
				switch.xform_a = xform
			elif index == 1:
				xform.basis = xform.basis.rotated(Vector3.UP, PI)
				xform.basis = xform.basis.orthonormalized()
				switch.xform_b = xform

	redraw(gizmo)

func get_handle_value(gizmo: EditorSpatialGizmo, index: int) -> Transform:
	var switch := gizmo.get_spatial_node() as DirectionSwitch
	return [
		switch.xform_a,
		switch.xform_b,
	][index]

func commit_handle(gizmo: EditorSpatialGizmo, index: int, restore: Transform, cancel: bool = false) -> void:
	var switch := gizmo.get_spatial_node() as DirectionSwitch
	var handle_name := get_handle_name(gizmo, index)
	if cancel:
		switch.set(handle_name, restore)
	else:
		var value := switch.get(handle_name) as Transform
		undo_redo.create_action("set " + handle_name)
		undo_redo.add_undo_property(switch, handle_name, restore)
		undo_redo.add_undo_property(switch, "radius", restore.origin.length())
		undo_redo.add_undo_method(self, "redraw", gizmo)
		undo_redo.add_do_property(switch, handle_name, value)
		undo_redo.add_do_property(switch, "radius", switch.radius)
		undo_redo.commit_action()
	redraw(gizmo)