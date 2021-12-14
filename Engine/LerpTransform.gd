class_name LerpTransform extends Spatial

export var lerp_speed := 5.0

onready var base_transform := transform

func _ready():
	set_as_toplevel(true)
	global_transform = base_transform * get_parent().global_transform

func _physics_process(delta: float) -> void:
	global_transform = global_transform.interpolate_with(base_transform * get_parent().global_transform, delta * lerp_speed)
