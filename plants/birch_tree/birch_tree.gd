extends BasePlant

@onready var collision_shape = $CollisionShape3D

func get_plant_path():
	return "res://plants/birch_tree/birch_tree.tscn"

func set_shape_interact(is_enabled := true):
	collision_shape.disabled = !is_enabled

func _on_set_is_dead(value):
	if value:
		$uploads_files_3120952_Tree/Tree/leafs.hide()
		$uploads_files_3120952_Tree/Tree/leafs_003.hide()
