@tool
extends Node3D

var character_scene: PackedScene = load("res://character/character.tscn")
var curr_character = null
var exploring: bool = false:
	set(value):
		if value:
			$UI.hide()
		else:
			$UI.show()
		exploring = value

@onready var env_parent = $Environment
var env_updated := true
@export var environment: PackedScene:
	set(value):
		if env_parent:
			env_updated = true
			for child in env_parent.get_children():
				child.queue_free() # Remove any previous children
			env_parent.add_child(value.instantiate()) # Add the new environment
		else:
			env_updated = false
		environment = value

var seed_button_pressed: bool = false
var curr_seed_button: SeedButton = null
var curr_plant_mesh: Node3D = null
var selected_pos: Vector3 = Vector3.ZERO:
	set(value):
		if value != Vector3.ZERO:
			$SelectedRing.show()
			$SelectedRing.global_position = selected_pos
		else:
			$SelectedRing.hide()
		selected_pos = value

func _ready():
	if not env_updated:
		environment = environment
		env_updated = true
	if Engine.is_editor_hint():
		return
	for seed_button in %SeedsMenu.seed_buttons:
		seed_button.seed_button_down.connect(_seed_button_pressed)
		seed_button.seed_button_up.connect(_seed_button_released)

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if exploring:
		if Input.is_action_pressed("escape"):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			if not curr_character:
				return
			curr_character.queue_free()
			$MovableCamera3D.cam.current = true
			curr_character = null
			exploring = false
		return
	
	# Handle seed drag/drop and click position	
	var pos = project_mouse_position()
	if Input.is_action_pressed("left_click"):
		if pos:
			selected_pos = pos
		else:
			selected_pos = Vector3.ZERO
	if seed_button_pressed and curr_plant_mesh:
		if pos:
			curr_seed_button.make_transparent(true)
			curr_plant_mesh.show()
			curr_plant_mesh.global_position = pos
		else:
			curr_plant_mesh.hide()
			curr_seed_button.make_transparent(false)
	elif curr_plant_mesh:
		if not pos:
			curr_plant_mesh.queue_free()
		curr_plant_mesh = null

func _seed_button_pressed(seed_button):
	seed_button_pressed = true
	curr_seed_button = seed_button
	if curr_seed_button.plant_scene:
		curr_plant_mesh = curr_seed_button.plant_scene.instantiate()
		curr_plant_mesh.hide()
		add_child(curr_plant_mesh)
		await get_tree().physics_frame

func _seed_button_released(_seed_button):
	seed_button_pressed = false
	curr_seed_button = null

var ray_length: float = 1000.0
func project_mouse_position():
	# Get the mouse position in screen coordinates
	var mouse_pos = $UI.get_global_mouse_position()
	
	# Create a ray from the camera
	var from = $MovableCamera3D.cam.project_ray_origin(mouse_pos)
	var to = from + $MovableCamera3D.cam.project_ray_normal(mouse_pos) * ray_length
	
	# Create a PhysicsRayQueryParameters3D object to define ray parameters
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.from = from
	ray_query.to = to
	
	# Perform the raycast
	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(ray_query)
	
	if result:
		# 'result.position' contains the collision point in the 3D world
		# result has some other useful info too (like normals, object IDs)
		return result.position

func _on_explore_button_pressed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	exploring = true
	curr_character = character_scene.instantiate()
	add_child(curr_character)
	await get_tree().physics_frame
	curr_character.global_position = selected_pos
	curr_character.cam.current = true
