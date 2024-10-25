extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
@onready var cam = $MovableCamera3D.cam

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("escape"):
		EventBus.exit_explore_mode.emit()
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle crouch.
	if Input.is_action_just_pressed("control"):
		$MovableCamera3D.position.y = 1.2
		$CollisionShape3D.shape.height = 0.9
		global_position.y -= 0.9/2.0
	if Input.is_action_just_released("control"):
		$MovableCamera3D.position.y = 1.6
		$CollisionShape3D.shape.height = 1.8
		global_position.y += 0.9/2.0
	
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	rotation_degrees.y = $MovableCamera3D.camrot_h * delta * 150
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
