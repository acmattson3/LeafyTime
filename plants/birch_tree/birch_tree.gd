extends BasePlant

@onready var collision_shape = $CollisionShape3D

func get_plant_path():
	return "res://plants/birch_tree/birch_tree.tscn"

func set_shape_interact(is_enabled := true):
	collision_shape.disabled = !is_enabled
