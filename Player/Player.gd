class_name Player extends Entity

const z_margin := 1.0

export var speed := 10.0
export var accel_ground := 5.0
export var accel_air := 1.25
export var jump_power := 10.0
export var lock_z := true

var velocity := Vector3.ZERO

var last_wall : Vector3
var last_wall_elapsed := 0.0
var last_floor_elapsed := 0.0

var move_xform : Transform
var lerp_move_xform : Transform
var lerp_move_xform_duration := 0.5
var lerp_move_xform_t := 1.0
var direction_switch : DirectionSwitch

func _ready() -> void:
	move_xform = global_transform
	lerp_move_xform = move_xform

func _physics_process(delta: float) -> void:
	# interpolate move xform
	var direction_switches : Array = $DirectionSwitchSensor.get_overlapping_areas()
	if direction_switches.size() > 0:
		if direction_switches.size() >= 2:
			lerp_move_xform = direction_switches[0].interpolate_xform(global_transform)
			lerp_move_xform = lerp_move_xform.interpolate_with(direction_switches[1].interpolate_xform(global_transform), 0.5)
		else:
			direction_switch = direction_switches[0]
			lerp_move_xform = direction_switch.interpolate_xform(global_transform)
	elif direction_switch:
		lerp_move_xform = direction_switch.closest(global_transform)
		lerp_move_xform_t = 0.0
		direction_switch = null
	if lerp_move_xform.basis.z.dot(global_transform.basis.z) < 0.0:
		lerp_move_xform.basis = lerp_move_xform.basis.rotated(lerp_move_xform.basis.y, PI)

	move_xform = move_xform.interpolate_with(lerp_move_xform, lerp_move_xform_t)
	lerp_move_xform_t = clamp(lerp_move_xform_t + delta / lerp_move_xform_duration, 0, 1)

	# HACK after a direction switch, the basis isn't quite perfect (fp precision error I think), causes snap not to work
	global_transform.basis = fix_basis_precision(move_xform.basis)

	var xform := global_transform
	var xform_inv := xform.inverse()
	var z_offset := (move_xform.inverse() * xform.origin).z

	# get inputs
	var move := Vector3.ZERO
	move.x = (int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left")))

	# some z movement stuff? maybe used to pick branches, but feels weird right now
	move.z = (int(Input.is_action_pressed("move_down")) - int(Input.is_action_pressed("move_up")))
	if abs(z_offset) <= 0.1 && move.z == 0:
		velocity.z = 0
		move.z = 0
	elif abs(z_offset) >= z_margin && sign(move.z) == sign(z_offset):
		velocity.z = 0
		move.z = 0
	else:
		move.z -= z_offset / z_margin

	var on_floor : bool = is_on_floor()
	var on_wall : bool = is_on_wall()
	var accel = accel_ground if on_floor else accel_air

	# test floor
	if on_floor:
		last_floor_elapsed = 0.0
	else:
		last_floor_elapsed += delta

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
	else:
		last_wall_elapsed += delta

	# separate velocity.xz from velocity.y
	var velocity_y = velocity.y
	if !on_floor:
		velocity.y = 0
	var target_velocity = lerp(velocity, move * speed, accel * delta)

	# prepare snap_vec
	var snap_vec := xform.basis.y.normalized() * -0.25
	if velocity_y > 0:
		snap_vec = Vector3.ZERO

	# apply move
	velocity = xform_inv.basis * move_and_slide_with_snap(xform.basis * target_velocity, snap_vec, xform.basis.y, true)

	# lock local z axis
	# velocity.x += (xform_inv.basis * move_and_slide((move_xform.basis.z * -z_offset) / delta, xform.basis.y, true)).x

	# jump
	if last_floor_elapsed < 0.125 && Input.is_action_just_pressed("jump"):
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
	# if Input.is_action_just_pressed("move_up"):
	# 	global_transform.basis = global_transform.basis.rotated(global_transform.basis.y, PI)
	# 	velocity.x *= -1
	# 	Engine.time_scale = 0.3
	# 	yield(get_tree().create_timer(0.5), "timeout")
	# 	Engine.time_scale = 1

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
