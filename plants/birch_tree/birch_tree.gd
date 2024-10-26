extends BasePlant

@onready var collision_shape = $CollisionShape3D

func set_shape_interact(is_enabled := true):
	collision_shape.disabled = !is_enabled
