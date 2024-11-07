@tool
extends Node3D

@onready var env_parent = $Environment # Where environments are kept
@export var environment: PackedScene # The current environment
var curr_env = null

var character_scene: PackedScene = load("res://character/character.tscn")
var curr_character = null # The current character scene

var seed_button_pressed: bool = false # Are we pressing/dragging a seed button?
var curr_seed_button: SeedButton = null # The current button we are dragging
var curr_plant: BasePlant = null # The plant associated with our currently dragged button

@onready var selected_ring = $SelectedRing # The ring that shows the selected position

func _ready():
	# Initialize environment
	if environment and env_parent:
		for child in env_parent.get_children(): # Remove current environments, if any
			child.queue_free()
		curr_env = environment.instantiate()
		env_parent.add_child(curr_env) # Add environment from export
	
	if Engine.is_editor_hint():
		return # Keep editor from running unnecessary code
	
	# Connect to EventBus signals
	EventBus.seed_button_pressed.connect(_on_seed_button_pressed)
	EventBus.seed_button_released.connect(_on_seed_button_released)
	EventBus.enter_explore_mode.connect(_on_enter_explore_mode)
	EventBus.exit_explore_mode.connect(_exit_explore_mode)
	EventBus.load_game.connect(_on_load_game)
	
	EventBus.resume_study_after_exit.connect(_on_resume_study_after_exit)
	EventBus.start_study_session.connect(_on_start_study_session)
	EventBus.start_break.connect(_on_start_break)
	EventBus.resume_study_session.connect(_on_resume_study_session)
	EventBus.stop_study_session.connect(_on_stop_study_session)
	EventBus.toggle_env_input.connect(_on_toggle_env_input)

var do_env_input: bool = true
func _on_toggle_env_input(is_on):
	do_env_input = is_on

func _on_start_study_session(_plant: BasePlant):
	selected_ring.hide()
	%ToggleStudyBreakButton.text = "Start Break"
	%ToggleStudyBreakButton.show()
	%StopStudyButton.show()
	%ExploreButton.disabled = true
	%TimeRemainingLabel.show()
	%TimeRemaining.show()
	%TimeRemainingLabel.text = "Study Time Left:"

func _on_start_break():
	selected_ring.show()
	%ToggleStudyBreakButton.disabled = false
	%StopStudyButton.disabled = false
	%ExploreButton.disabled = false
	%TimeRemainingLabel.text = "Break Time Left:"
	%ToggleStudyBreakButton.text = "Resume Studying"

func _on_resume_study_session():
	selected_ring.hide()
	%ToggleStudyBreakButton.disabled = false
	%StopStudyButton.disabled = false
	%ExploreButton.disabled = true
	%TimeRemainingLabel.text = "Study Time Left:"

func _on_stop_study_session(_completed):
	selected_ring.show()
	%ToggleStudyBreakButton.hide()
	%StopStudyButton.hide()
	%ExploreButton.disabled = false
	%TimeRemainingLabel.hide()
	%TimeRemaining.hide()

func _on_resume_study_after_exit(_plant_name):
	print("Resuming after exit!")
	selected_ring.hide()
	%ToggleStudyBreakButton.text = "Resume Studying"
	%ToggleStudyBreakButton.show()
	%StopStudyButton.show()
	%ExploreButton.disabled = true
	%TimeRemainingLabel.show()
	%TimeRemaining.show()
	%TimeRemainingLabel.text = "Break Time Left:"

func _on_load_game():
	%TickButton.value = GameManager.get_study_break_ratio()
	%WhitelistCheckBox.button_pressed = GameManager.get_do_whitelist()
	var words: Array = GameManager.get_greylist()
	var idx: int = 0
	for word in words:
		%WhitelistTextEdit.text += word
		idx += 1
		if idx != len(words):
			%WhitelistTextEdit.text += ","
	
	var plants: Dictionary = GameManager.get_plants()
	for plant_name in plants.keys():
		var new_plant = load(plants[plant_name].path).instantiate()
		new_plant.is_dead = plants[plant_name].is_dead
		new_plant.name = plant_name
		curr_env.add_child(new_plant, true)
		new_plant.global_position = plants[plant_name].pos
		new_plant.rotation = plants[plant_name].rot
		new_plant.scale = plants[plant_name].scale
		new_plant.set_shape_interact(true)
		if new_plant.name == GameManager.get_studied_plant_name():
			# We were studying this plant before we last exited!
			StudyManager.set_active_plant(new_plant)
			
	%LoadingLabel.hide()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return # Keep editor from running unnecessary code
	if not GameManager.done_emit_load:
		return # We haven't loaded save data yet!
	if EventBus.exploring:
		return # The viewer should do nothing if we are exploring an environment.
	
	if StudyManager.is_studying():
		%TimeRemaining.text = StudyManager.get_readable_time_remaining()
		return
	
	if not do_env_input:
		return
	
	# Handle click position
	var result = project_mouse_position()
	if Input.is_action_pressed("left_click"):
		if result_is_valid(result):
			selected_ring.global_position = result.position
			if not StudyManager.is_studying():
				selected_ring.show()
	
	# Handle plant drag/drop
	if seed_button_pressed and curr_plant:
		if result_is_valid(result):
			if Input.is_action_pressed("rotate_left"):
				curr_plant.rotation.y += delta
			if Input.is_action_pressed("rotate_right"):
				curr_plant.rotation.y -= delta
			curr_seed_button.make_transparent(true)
			curr_plant.show()
			curr_plant.global_position = result.position
		else:
			curr_plant.hide()
			curr_seed_button.make_transparent(false)

# Checks if a given intersect_ray() Dictionary is valid for placing a plant
func result_is_valid(result):
	if not result:
		return false # No result
	if result is not Dictionary:
		return false # Invalid type passed
	if not result.position:
		return false # Invalid position
	if result.collider is BasePlant:
		return false # Placing on another plant
	if result.collider == $WorldBorder:
		return false # Placing on a world border
	return true

# Handle when we have clicked a seed button
func _on_seed_button_pressed(seed_button):
	if StudyManager.is_studying():
		var message = "You are currently studying. To select new plants, "
		message += "you must finish studying or stop your session."
		EventBus.show_info.emit(message)
		return # We are studying; don't mess with buttons!
	
	curr_seed_button = seed_button
	if seed_button.unlocked:
		seed_button_pressed = true
		if curr_seed_button.plant_scene: # The button has a plant associated with it
			curr_plant = curr_seed_button.plant_scene.instantiate()
			curr_plant.hide()
			curr_env.add_child(curr_plant, true)
	else:
		print("Plant is locked!")
		if curr_seed_button.plant_scene:
			# Instantiate a plant but never put it in the world!
			SoundManager.play_neutral()
			var temp = curr_seed_button.plant_scene.instantiate()
			var confirm_message = "Are you sure you want to unlock "
			confirm_message += temp.get_plant_name()
			confirm_message += "? This will take "+temp.get_readable_study_duration()+"."
			EventBus.show_confirm.emit(confirm_message)
			if await EventBus.popup_user_input:
				var locked_plant_scene = curr_seed_button.plant_scene.instantiate()
				EventBus.start_study_session.emit(locked_plant_scene)

# Handle when we have released a seed button. We may be dropping it into:
#   * The seeds menu
#   * An invalid position
#   * The environment
func _on_seed_button_released(seed_button):
	if StudyManager.is_studying():
		return # We are studying; don't mess with buttons!
	
	if seed_button.unlocked:
		seed_button_pressed = false
		curr_seed_button = null
		if not curr_plant.visible: # The plant cannot be placed
			curr_plant.queue_free() # Get rid of it
		else: # The plant can be placed
			SoundManager.play_neutral()
			var confirm_message = "Are you sure you want to place a "
			confirm_message += curr_plant.plant_name+" here? This cannot be undone, and "
			confirm_message += "will take "+curr_plant.get_readable_study_duration()+"."
			EventBus.show_confirm.emit(confirm_message)
			if await EventBus.popup_user_input:
				EventBus.start_study_session.emit(curr_plant)
				curr_plant.set_shape_interact(true) # Make it have collisions
			else:
				curr_plant.queue_free()
		curr_plant = null

# Handle when the explore button is pressed (enter explore mode)
func _on_explore_button_pressed():
	SoundManager.play_happy()
	EventBus.enter_explore_mode.emit()

# Handle entering explore mode
func _on_enter_explore_mode():
	# Handle the transition into exploring
	EventBus.exploring = true
	$UI.hide()
	selected_ring.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Instantiate and set up the first-person character scene
	curr_character = character_scene.instantiate()
	add_child(curr_character)
	curr_character.global_position = selected_ring.global_position
	curr_character.cam.current = true

# Handle exiting explore mode
func _exit_explore_mode():
	# Handle the transition out of explore mode
	EventBus.exploring = false
	$UI.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Remove the first-person character and reset back to the viewer
	if curr_character:
		curr_character.queue_free()
		curr_character = null
	$MovableCamera3D.cam.current = true

# Find the mouse position in the 3D environment
# Returns `result` consisting of:
#   * collider: The colliding object
#   * collider_id: The colliding object's ID
#   * normal: The object's surface normal at the intersection point, or Vector3(0, 0, 0) if invalid
#   * position: The intersection point
#   * face_index: The face index at the intersection point (for ConcavePolygonShape3D's only)
#   * rid: The intersecting object's RID
#   * shape: The shape index of the colliding shape
var ray_length: float = 1000.0 # How far away from the camera do we look?
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
		return result
	return null

# Users can press to stop the current study session
func _on_stop_study_button_pressed() -> void:
	var active_plant_name = GameManager.get_studied_plant_name()
	if active_plant_name == "":
		var new_plant = StudyManager.get_active_plant()
		if new_plant:
			active_plant_name = new_plant.plant_name
	var confirm_message = "Are you sure you want to cancel this study session? "
	SoundManager.play_neutral()
	if GameManager.is_plant_unlocked(active_plant_name):
		confirm_message += active_plant_name+" will die!"
	else:
		confirm_message += active_plant_name+" will not be unlocked!"
	EventBus.show_confirm.emit(confirm_message)
	if await EventBus.popup_user_input:
		EventBus.stop_study_session.emit(false)

# Toggle between studying and being on a break
func _on_toggle_study_break_button_pressed() -> void:
	if StudyManager.is_on_break():
		SoundManager.play_neutral()
		EventBus.resume_study_session.emit()
		%ToggleStudyBreakButton.text = "Start Break"
	else:
		SoundManager.play_neutral()
		EventBus.start_break.emit()
		%ToggleStudyBreakButton.text = "Resume Studying"

# Toggle settings window visibility
func _on_settings_button_pressed() -> void:
	EventBus.toggle_env_input.emit(%SettingsWindow.visible)
	%SettingsWindow.visible = !%SettingsWindow.visible

func _on_whitelist_text_edit_text_changed() -> void:
	StudyManager.set_greylist(%WhitelistTextEdit.text.split(','))

func _on_whitelist_check_box_toggled(toggled_on: bool) -> void:
	StudyManager.whitelist = toggled_on

func _on_tick_button_value_changed(value: float) -> void:
	StudyManager.set_study_break_ratio(value)
