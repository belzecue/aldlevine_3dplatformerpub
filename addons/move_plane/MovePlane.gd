tool

extends Spatial

class_name MovePlane

export var size := Vector2(30, 30) setget set_size

export var bottom_left := Vector2(-15, -15)
export var bottom_right := Vector2(15, -15)
export var top_right := Vector2(15, 15)
export var top_left := Vector2(-15, 15)

var bottom : Vector2 setget set_bottom, get_bottom
var left : Vector2 setget set_left, get_left
var top : Vector2 setget set_top, get_top
var right : Vector2 setget set_right, get_right

var mesh : QuadMesh
var mesh_instance : MeshInstance

func _ready() -> void:
	if Engine.editor_hint && false:
		if mesh_instance:
			mesh_instance.queue_free()
		mesh_instance = MeshInstance.new()
		mesh = QuadMesh.new()
		mesh_instance.material_override = preload("MovePlaneMaterial.tres")
		mesh_instance.mesh = mesh
		add_child(mesh_instance)
		set_size(size)

func set_size(s: Vector2) -> void:
	size = s
	if mesh:
		mesh.size = size

func set_bottom(v: Vector2) -> void:
	bottom_left.y = v.y
	bottom_right.y = v.y

func get_bottom() -> Vector2:
	return lerp(bottom_left, bottom_right, 0.5)

func set_left(v: Vector2) -> void:
	bottom_left.x = v.x
	top_left.x = v.x

func get_left() -> Vector2:
	return lerp(bottom_left, top_left, 0.5)

func set_top(v: Vector2) -> void:
	top_left.y = v.y
	top_right.y = v.y

func get_top() -> Vector2:
	return lerp(top_left, top_right, 0.5)

func set_right(v: Vector2) -> void:
	bottom_right.x = v.x
	top_right.x = v.x

func get_right() -> Vector2:
	return lerp(bottom_right, top_right, 0.5)

func get_plane() -> Plane:
	var bottom_left_g = global_transform.xform(Vector3(bottom_left.x, bottom_left.y, 0))
	var bottom_right_g = global_transform.xform(Vector3(bottom_right.x, bottom_right.y, 0))
	var top_right_g = global_transform.xform(Vector3(top_right.x, top_right.y, 0))
	return Plane(bottom_left_g, bottom_right_g, top_right_g)