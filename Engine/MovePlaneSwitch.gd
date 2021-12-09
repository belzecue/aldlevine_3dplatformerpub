extends Area

class_name MovePlaneSwitch

export var _x_pos : NodePath
onready var x_pos : MovePlane = get_node_or_null(_x_pos)
export var _x_neg : NodePath
onready var x_neg : MovePlane = get_node_or_null(_x_neg)

export var _z_pos : NodePath
onready var z_pos : MovePlane = get_node_or_null(_z_pos)
export var _z_neg : NodePath
onready var z_neg : MovePlane = get_node_or_null(_z_neg)

var radius := 0.0

var temp_move_plane := MovePlane.new()

enum SwitchDirection {
	XPos,
	XNeg,
	ZPos,
	ZNeg
}

func _init() -> void:
	collision_layer = CollisionLayers.move_plane_switch

func _ready() -> void:
	var col_shape := get_node_or_null("CollisionShape") as CollisionShape
	var cylinder := col_shape.shape as CylinderShape
	radius = cylinder.radius
	add_child(temp_move_plane)

func interpolate(from: int, to: int, position: Vector3) -> MovePlane:
	var from_pos_node : Node
	var from_plane : MovePlane
	match from:
		SwitchDirection.XPos:
			from_pos_node = get_node("x_pos")
			from_plane = x_pos
		SwitchDirection.XNeg:
			from_pos_node = get_node("x_neg")
			from_plane = x_neg
		SwitchDirection.ZPos:
			from_pos_node = get_node("z_pos")
			from_plane = z_pos
		SwitchDirection.ZNeg:
			from_pos_node = get_node("z_neg")
			from_plane = z_neg
	var from_pos : Vector3 = from_pos_node.global_transform.origin if from_pos_node else global_transform.origin

	var to_pos_node : Node
	var to_plane : MovePlane
	match to:
		SwitchDirection.XPos:
			to_pos_node = get_node("x_pos")
			to_plane = x_pos
		SwitchDirection.XNeg:
			to_pos_node = get_node("x_neg")
			to_plane = x_neg
		SwitchDirection.ZPos:
			to_pos_node = get_node("z_pos")
			to_plane = z_pos
		SwitchDirection.ZNeg:
			to_pos_node = get_node("z_neg")
			to_plane = z_neg
	var to_pos : Vector3 = to_pos_node.global_transform.origin if to_pos_node else global_transform.origin
	
	temp_move_plane.global_transform.origin = position

	var from_dist = (Vector3(1,0,1) * position).distance_to(Vector3(1,0,1) * from_pos)
	var to_dist = (Vector3(1,0,1) * position).distance_to(Vector3(1,0,1) * to_pos)
	var weight = from_dist / (from_dist + to_dist)
	temp_move_plane.global_transform.basis = from_plane.global_transform.basis.slerp(to_plane.global_transform.basis, weight)

	return temp_move_plane

func closest(position: Vector3) -> MovePlane:
	var closest_dist = INF
	var closest_plane : MovePlane
	for plane_name in ["x_pos", "x_neg", "z_pos", "z_neg"]:
		var pos_node := get_node(plane_name)
		var dist := position.distance_squared_to(pos_node.global_transform.origin)
		if dist < closest_dist:
			closest_dist = dist
			closest_plane = get(plane_name)
	return closest_plane
