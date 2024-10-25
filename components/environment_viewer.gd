@tool
extends Node3D

@onready var env_parent = $Environment
@export var environment: PackedScene
var exploring: bool = false
var character_scene: PackedScene = load("res://character/character.tscn")
var curr_character = null
var seed_button_pressed: bool = false
var curr_seed_button: SeedButton = null
var curr_plant_mesh: Node3D = null

@onready var selected_ring = $SelectedRing

func _ready():
	# Initialize environment
	if environment and env_parent:
		for child in env_parent.get_children():
			child.queue_free()
		env_parent.add_child(environment.instantiate())
	
	# Keep editor from running unnecessary code
	if Engine.is_editor_hint():
		return
	
	# Connect to EventBus signals
	EventBus.seed_button_pressed.connect(_on_seed_button_pressed)
	EventBus.seed_button_released.connect(_on_seed_button_released)
	EventBus.enter_explore_mode.connect(_on_explore_button_pressed)
	EventBus.exit_explore_mode.connect(_exit_explore_mode)

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if exploring:
		return

	# Handle seed drag/drop and click position
	var pos = project_mouse_position()
	if Input.is_action_pressed("left_click"):
		if pos:
			selected_ring.global_position = pos
			selected_ring.show()
		else:
			selected_ring.hide()

	if seed_button_pressed and curr_plant_mesh:
		if pos:
			curr_seed_button.make_transparent(true)
			curr_plant_mesh.show()
			curr_plant_mesh.global_position = pos
		else:
			curr_plant_mesh.hide()
			curr_seed_button.make_transparent(false)

func _on_seed_button_pressed(seed_button):
	seed_button_pressed = true
	curr_seed_button = seed_button
	if curr_seed_button.plant_scene:
		curr_plant_mesh = curr_seed_button.plant_scene.instantiate()
		curr_plant_mesh.hide()
		add_child(curr_plant_mesh)

func _on_seed_button_released(_seed_button):
	seed_button_pressed = false
	curr_seed_button = null
	if not curr_plant_mesh.visible:
		curr_plant_mesh.queue_free()
	curr_plant_mesh = null

func _on_explore_button_pressed():
	$UI.hide()
	selected_ring.hide()
	exploring = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	curr_character = character_scene.instantiate()
	add_child(curr_character)
	curr_character.global_position = selected_ring.global_position
	curr_character.cam.current = true

func _exit_explore_mode():
	$UI.show()
	exploring = false
	if curr_character:
		curr_character.queue_free()
		curr_character = null
	$MovableCamera3D.cam.current = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

var ray_length: float = 1000.0
func project_mouse_position():
	var mouse_pos = $UI.get_global_mouse_position()
	var from = $MovableCamera3D.cam.project_ray_origin(mouse_pos)
	var to = from + $MovableCamera3D.cam.project_ray_normal(mouse_pos) * ray_length

	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.from = from
	ray_query.to = to

	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(ray_query)

	if result:
		return result.position
	return null
