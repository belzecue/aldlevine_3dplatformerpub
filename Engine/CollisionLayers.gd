extends Node

var default := 0
var move_plane_switch := 0

func _init() -> void:
	for i in range(1, 33):
		var layer_name := ProjectSettings.get_setting(str("layer_names/3d_physics/layer_", i)) as String
		if layer_name && layer_name.length() > 0:
			var key := layer_name.to_lower().replace(" ", "_")
			set(key, 1 << (i - 1))
