extends BasePlant

@onready var collision_shape = $CollisionShape3D

func get_plant_path():
	return "res://plants/spruce_tree/spruce_tree.tscn"

func _on_set_is_dead(_value):
	pass

func set_shape_interact(is_enabled := true):
	collision_shape.disabled = !is_enabled
