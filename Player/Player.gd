extends KinematicBody

export var speed := 10.0
export var accel_ground := 5.0
export var accel_air := 1.25
export var jump_power := 10.0
export var lock_z := true

var velocity := Vector3.ZERO

var last_wall : Vector3
var last_wall_elapsed := 0.0

# onready var move_plane : MovePlane = get_node("/root/Spatial/MovePlanes/MovePlane")
var move_plane := MovePlane.new()
var move_plane_flipped := false
var move_plane_switch : MovePlaneSwitch

func _ready() -> void:
	add_child(move_plane)
	move_plane.set_as_toplevel(true)
	move_plane.global_transform = global_transform

func _physics_process(delta: float) -> void:
	# interpolate move plane
	var move_plane_switches : Array = $MovePlaneSwitchSensor.get_overlapping_areas()
	if move_plane_switches.size() > 0:
		move_plane_switch = move_plane_switches[0]
		move_plane.global_transform = move_plane_switch.interpolate(MovePlaneSwitch.SwitchDirection.XNeg, MovePlaneSwitch.SwitchDirection.XPos, global_transform.origin).global_transform
	elif move_plane_switch:
		move_plane.global_transform = move_plane_switch.closest(global_transform.origin).global_transform
		move_plane_switch = null
	global_transform.basis = move_plane.transform.basis
	if move_plane_flipped:
		global_transform.basis = global_transform.basis.rotated(Vector3.UP, -PI)


	# get inputs
	var move := Vector3.ZERO
	move.x = (int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left")))
	var on_floor : bool = is_on_floor()
	var on_wall : bool = is_on_wall()
	var accel = accel_ground if on_floor else accel_air

	# test wall
	if on_wall:
		last_wall_elapsed = 0.0
		var max_normal_x = 0.0
		var wall = null
		for i in get_slide_count():
			var coll := get_slide_collision(i)
			var normal = global_transform.basis.inverse().xform(coll.normal)
			var normal_x := abs(normal.x)
			if normal_x > max_normal_x:
				max_normal_x = normal_x
				wall = normal
		if wall:
			last_wall = wall
		else:
			on_wall = false
	last_wall_elapsed += delta

	# prepare velocity
	var velocity_y = velocity.y
	if !on_floor:
		velocity.y = 0
	var target_velocity = lerp(velocity, move.normalized() * speed, accel * delta)

	# prepare snap_vec
	var snap_vec := Vector3.DOWN * 0.25
	if velocity_y > 0:
		snap_vec = Vector3.ZERO

	# apply move
	velocity = global_transform.basis.inverse() * move_and_slide_with_snap(global_transform.basis * target_velocity, snap_vec, Vector3.UP, true)

	# TODO lock local z axis
	var plane := move_plane.get_plane()
	var plane_isect = plane.intersects_ray(global_transform.origin, global_transform.basis.z)
	if plane_isect == null:
		plane_isect = plane.intersects_ray(global_transform.origin, -global_transform.basis.z)
	velocity.x += (global_transform.basis.inverse() * move_and_slide((plane_isect - global_transform.origin) / delta, Vector3.UP, true)).x

	# jump
	if on_floor && Input.is_action_just_pressed("jump"):
		velocity_y += jump_power
		snap_vec = Vector3.ZERO
	elif Input.is_action_just_released("jump") && velocity_y > 0:
		velocity_y *= 0.5

	# wall_jump
	if !on_floor && last_wall_elapsed < 0.125 && Input.is_action_just_pressed("jump"):
		velocity_y = jump_power * sqrt(2.0) / 2.0
		velocity += last_wall * jump_power * sqrt(2.0) / 2.0

	# gravity
	var grav : float = PhysicsServer.area_get_param(get_world().space, PhysicsServer.AREA_PARAM_GRAVITY)
	velocity_y -= grav * delta
	velocity_y = move_and_slide_with_snap(Vector3(0, velocity_y, 0), snap_vec, Vector3.UP).y

	# resolve velocity
	velocity.y = velocity_y

	# flip camera
	if Input.is_action_just_pressed("move_up"):
		move_plane_flipped = !move_plane_flipped
		velocity.x *= -1
		Engine.time_scale = 0.3
		yield(get_tree().create_timer(0.5), "timeout")
		Engine.time_scale = 1
