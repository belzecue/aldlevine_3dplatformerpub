tool

class_name DirectionSwitch extends Area

export var radius := 1.0 setget set_radius

export var thickness_a := Vector2.ONE
export var thickness_b := Vector2.ONE

export var offset_a := Vector3.ZERO
export var offset_b := Vector3.ZERO

export var detail := 8

export var xform_a : Transform
export var xform_b : Transform

func _init() -> void:
	collision_layer = CollisionLayers.direction_switch
	# connect("area_entered", self, "area_entered")
	# connect("area_exited", self, "area_exited")

func _ready() -> void:
	if !Engine.editor_hint:
		var shapes := generate_collider_shapes()
		for shape in shapes:
			var col_shape := CollisionShape.new()
			col_shape.shape = shape
			add_child(col_shape)
	else:
		# suppress the editor warning about missing collision shape
		add_child(CollisionShape.new())

func set_radius(v: float) -> void:
	radius = v
	xform_a.origin = xform_a.origin.normalized() * radius
	xform_b.origin = xform_b.origin.normalized() * radius

func generate_collider_slices() -> Array:
	var slices := []
	slices.resize(detail + 1)

	var base_slice := PoolVector3Array([
		Vector3(0, -1, -1), Vector3(0, -1,  1),
		Vector3(0,  1,  1), Vector3(0,  1, -1),
	])
	for i in slices.size():
		var t : float = i / float(detail)
		var xform := interpolate(t)
		var thickness : Vector2 = lerp(thickness_a, thickness_b, t)
		var scale_xform := Transform().scaled(Vector3(1, thickness.y, thickness.x))
		slices[i] = xform.xform(scale_xform.xform(base_slice))

	return slices

func generate_collider_shapes() -> Array:
	var slices := generate_collider_slices()
	var shapes := []
	for i in slices.size() - 1:
		var shape := ConvexPolygonShape.new()
		var points := PoolVector3Array()
		points.append_array(slices[i])
		points.append_array(slices[i + 1])
		shape.points = points
		shapes.append(shape)
	return shapes

func interpolate(t: float) -> Transform:
	var xa := self.xform_a
	var xb := self.xform_b
	var q0 : Vector3 = lerp(xa.origin, Vector3.ZERO, t)
	var q1 : Vector3 = lerp(Vector3.ZERO, xb.origin, t)
	var origin : Vector3 = lerp(q0, q1, t)
	var basis := xa.basis.slerp(xb.basis, t)
	return Transform(basis, origin)

func interpolate_xform(xform: Transform) -> Transform:
	var xform_local : Transform = global_transform.inverse() * xform
	xform_local.origin.y = 0
	# find where 2 xforms intersect along their x axes
	var seg_a_dir := Vector3(xform_a.origin.z, 0, xform_a.origin.x)
	var seg_a_begin := xform_a.origin - seg_a_dir * 100
	var seg_a_end := xform_a.origin + seg_a_dir * 100
	var seg_b_dir := Vector3(xform_b.origin.z, 0, xform_b.origin.x)
	var seg_b_begin := xform_b.origin - seg_b_dir * 100
	var seg_b_end := xform_b.origin + seg_b_dir * 100
	var seg_a_begin_2 := Vector2(seg_a_begin.x, seg_a_begin.z)
	var seg_a_end_2 := Vector2(seg_a_end.x, seg_a_end.z)
	var seg_b_begin_2 := Vector2(seg_b_begin.x, seg_b_begin.z)
	var seg_b_end_2 := Vector2(seg_b_end.x, seg_b_end.z)
	var isect = Geometry.segment_intersects_segment_2d(seg_a_begin_2, seg_a_end_2, seg_b_begin_2, seg_b_end_2)
	# if we have an intersection use angle to find interp t
	if isect:
		var dir_a := Vector3(isect.x, 0, isect.y).direction_to(seg_a_begin)
		var dir_b := Vector3(isect.x, 0, isect.y).direction_to(seg_b_begin)
		var dir_x := Vector3(isect.x, 0, isect.y).direction_to(xform_local.origin)
		var angle_ab := acos(dir_a.dot(dir_b))
		var angle_ax := acos(dir_a.dot(dir_x))
		var t := clamp((angle_ax - angle_ab) / angle_ab, 0, 1)
		return global_transform * interpolate(1.0 - t)

	# uh oh, x axes are parallel! cheat and use origin distance
	var da := xform_local.origin.distance_to(xform_a.origin)
	var db := xform_local.origin.distance_to(xform_b.origin)
	var t := da / (da + db)
	return global_transform * interpolate(t)

func closest(xform: Transform) -> Transform:
	# var da := xform.origin.distance_to(global_transform * xform_a.origin)
	# var db := xform.origin.distance_to(global_transform * xform_b.origin)
	# if da < db:
	# 	return global_transform * xform_a
	# return global_transform * xform_b
	var xa := global_transform * xform_a
	var xb := global_transform * xform_b

	if xform.basis.z.dot(xa.basis.z) < 0:
		xform.basis = xform.basis.rotated(xform.basis.y, PI)
	var da := xform.basis.x.distance_squared_to(xa.basis.x) + xform.basis.y.distance_squared_to(xa.basis.y) + xform.basis.z.distance_squared_to(xa.basis.z)
	if xform.basis.z.dot(xb.basis.z) < 0:
		xform.basis = xform.basis.rotated(xform.basis.y, PI)
	var db := xform.basis.x.distance_squared_to(xb.basis.x) + xform.basis.y.distance_squared_to(xb.basis.y) + xform.basis.z.distance_squared_to(xb.basis.z)
	if da < db:
		return xa
	return xb


func ray_intersects_ray(a_origin: Vector3, a_direction: Vector3, b_origin: Vector3, b_direction: Vector3) -> Vector3:
	var dx := b_origin.x - a_origin.x
	var dz := b_origin.z - a_origin.z
	var det := b_direction.x * a_direction.z - b_direction.z * a_direction.x
	var u := (dz * b_direction.x - dx * b_direction.z) / det
	var v := (dz * a_direction.x - dx * a_direction.z) / det
	return Vector3(u, 0, v)
