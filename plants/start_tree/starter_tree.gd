extends BasePlant

@onready var collision_shape = $StaticBody3D/CollisionShape3D

func set_shape_interact(is_enabled := true):
	collision_shape.disabled = !is_enabled
