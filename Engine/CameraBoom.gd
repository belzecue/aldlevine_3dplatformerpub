extends Spatial


onready var previous_transform = global_transform

export var follow_speed_max := Vector2(10.0, 10.0)
export var swing_speed := Vector2(50.0, 20.0)

export var swing_min := Vector2(-15, 22.5)
export var swing_max := Vector2(7.5, -22.5)

export var swing_curve_y : Curve
export var swing_curve_x : Curve

var camera_swing_y := 0.0
var camera_swing_x := 0.0

func _physics_process(delta: float) -> void:
	var velocity : Vector3 = (global_transform.origin - previous_transform.origin) / delta
	previous_transform = global_transform
	# var target_camera_swing_y = lerp_neg(swing_min.y, swing_max.y, sign_interpolate(swing_curve_y, clamp(velocity.rotated(Vector3.UP, get_parent().rotation.y).x / follow_speed_max.y, -1, 1)))
	var target_camera_swing_y = lerp_neg(swing_min.y, swing_max.y, sign_interpolate(swing_curve_y, clamp((global_transform.basis.inverse() * velocity).x / follow_speed_max.y, -1, 1)))
	var target_camera_swing_x = lerp_neg(swing_min.x, swing_max.x, sign_interpolate(swing_curve_x, clamp(velocity.y / follow_speed_max.x, -1, 1)))
	camera_swing_y = lerp(camera_swing_y, target_camera_swing_y, delta * swing_speed.y)
	camera_swing_x = lerp(camera_swing_x, target_camera_swing_x, delta * swing_speed.x)
	rotation_degrees.y = camera_swing_y
	rotation_degrees.x = camera_swing_x

func lerp_neg(from: float, to: float, t: float) -> float:
	if t < 0:
		return lerp(0, from, -t)
	if t > 0:
		return lerp(0, to, t)
	return 0.0

func sign_pow(base: float, expo: float) -> float:
	return sign(base) * pow(abs(base), expo)

func sign_interpolate(curve: Curve, offset: float) -> float:
	return sign(offset) * curve.interpolate(abs(offset))
