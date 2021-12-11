extends KinematicBody

export var speed := 10.0
export var accel_ground := 5.0
export var accel_air := 1.25
export var jump_power := 10.0
export var lock_z := true

var velocity := Vector3.ZERO

var last_wall : Vector3
var last_wall_elapsed := 0.0

var move_xform : Transform
var direction_switch : DirectionSwitch

func _ready() -> void:
	move_xform = global_transform

func _physics_process(delta: float) -> void:
	# interpolate move xform
	var direction_switches : Array = $DirectionSwitchSensor.get_overlapping_areas()
	if direction_switches.size() > 0:
		if direction_switches.size() >= 2:
			move_xform = direction_switches[0].interpolate_xform(global_transform)
			move_xform = move_xform.interpolate_with(direction_switches[1].interpolate_xform(global_transform), 0.5)
		else:
			direction_switch = direction_switches[0]
			move_xform = direction_switch.interpolate_xform(global_transform)
	elif direction_switch:
		move_xform = direction_switch.closest(global_transform)
		direction_switch = null
	if move_xform.basis.z.dot(global_transform.basis.z) < 0.0:
		move_xform.basis = move_xform.basis.rotated(move_xform.basis.y, PI)

	# HACK after a direction switch, the basis isn't quite perfect (fp precision error I think), causes snap not to work
	global_transform.basis = fix_basis_precision(move_xform.basis)

	var xform := global_transform
	var xform_inv := xform.inverse()

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
			var normal = xform_inv.basis.xform(coll.normal)
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
	var snap_vec := xform.basis.y.normalized() * -0.25
	if velocity_y > 0:
		snap_vec = Vector3.ZERO

	# apply move
	velocity = xform_inv.basis * move_and_slide_with_snap(xform.basis * target_velocity, snap_vec, xform.basis.y, true)

	# lock local z axis
	var z_offset = (move_xform.inverse() * xform.origin).z
	velocity.x += (xform_inv.basis * move_and_slide((move_xform.basis.z * -z_offset) / delta, xform.basis.y, true)).x

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
	if on_wall && move.dot(last_wall) < 0.0 && velocity_y < 0:
		grav *= 0.5
	velocity_y -= grav * delta
	velocity_y = (xform_inv.basis * move_and_slide_with_snap(xform.basis.y * velocity_y, snap_vec, xform.basis.y)).y

	# resolve velocity
	velocity.y = velocity_y

	# flip camera
	if Input.is_action_just_pressed("move_up"):
		global_transform.basis = global_transform.basis.rotated(global_transform.basis.y, PI)
		velocity.x *= -1
		Engine.time_scale = 0.3
		yield(get_tree().create_timer(0.5), "timeout")
		Engine.time_scale = 1

func fix_basis_precision(basis: Basis) -> Basis:
	var epsilon := 0.0001

	if abs(basis.x.x) < epsilon:
		basis.x.x = 0
	if abs(basis.x.y) < epsilon:
		basis.x.y = 0
	if abs(basis.x.z) < epsilon:
		basis.x.z = 0

	if abs(basis.y.x) < epsilon:
		basis.y.x = 0
	if abs(basis.y.y) < epsilon:
		basis.y.y = 0
	if abs(basis.y.z) < epsilon:
		basis.y.z = 0

	if abs(basis.z.x) < epsilon:
		basis.z.x = 0
	if abs(basis.z.y) < epsilon:
		basis.z.y = 0
	if abs(basis.z.z) < epsilon:
		basis.z.z = 0

	return basis
