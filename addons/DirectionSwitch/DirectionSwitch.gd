tool

extends Area

class_name DirectionSwitch

export var radius := 1.0 setget set_radius

export var xform_a : Transform
export var xform_b : Transform

func _init() -> void:
	collision_layer = CollisionLayers.move_plane_switch

func set_radius(v: float) -> void:
	radius = v
	xform_a.origin = xform_a.origin.normalized() * radius
	xform_b.origin = xform_b.origin.normalized() * radius

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
	var da := xform_local.origin.distance_to(xform_a.origin)
	var db := xform_local.origin.distance_to(xform_b.origin)
	var t := da / (da + db)
	# print(t * t)
	t = smoothstep(0, 1, t)
	return global_transform * interpolate(t)

func closest(xform: Transform) -> Transform:
	var da := xform.origin.distance_to(global_transform * xform_a.origin)
	var db := xform.origin.distance_to(global_transform * xform_b.origin)
	if da < db:
		return global_transform * xform_a
	return global_transform * xform_b
