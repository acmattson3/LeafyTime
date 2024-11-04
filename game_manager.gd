extends Node
# GameManager
# Handles game states (saving/loading)

# Our current game state
# Structure:
# _game_state = 
#   {"environments":
#     {0: 
#       {"plants": 
#         {"PlantName0": 
#           {"path": "res://path/to/plant", 
#            "pos": Vector3(x,y,z), 
#            "rot": Vector3(x,y,z),
#            "scale": Vector3(x,y,z),
#            "is_dead": boolean,
#            "is_unlocked": boolean
#           }, # End "PlantName0"
#          ... More plants here
#         }, # End "plants" for env_id 0
#        ... More environment data here
#       }, # End environment with env_id 0
#      ... More environments here
#     }, # End environments
#    "unlocked_plants":
#      [
#       "PlantName0",
#       "PlantName1", 
#       ... More unlocked plants here
#      ],
#    "current_environment": 0,
#    "study_progress": 
#      {"plant_name": "PlantName0",
#       "break_duration": float,
#       "study_duration": float
#       "start_time": unix_time_int
#      }, # End study progress
#    ... More game state data here
#   } # End game state
var _game_state := {
	"environments": {},
	"unlocked_plants": [], # Requires that all plants have unique names
	"current_environment": 0, # The last loaded environment
	"study_progress": {}
}
const SAVE_FILE_PATH = "user://save_game.json"

var done_emit_load := false # Have we finished emitting EventBus.load_game?
const debugging = false

func _ready():
	#clear_save_file()
	_load_game_from_file() # Load data on startup
	EventBus.unlock_plant.connect(add_unlocked_plant)

func _notification(what):
	# Catch pressing X on the application window
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_game_to_file() # Save before we close!
		await get_tree().physics_frame
		get_tree().quit() # Do the default behavior too

func _process(_delta):
	if not done_emit_load:
		EventBus.load_game.emit()
		done_emit_load = true
	# Debugging keyboard shortcut to clear the game save file (likely removed later)
	if Input.is_key_pressed(KEY_F1) and Input.is_key_pressed(KEY_CTRL) and Input.is_key_pressed(KEY_ALT):
		clear_save_file()

func clear_save_file():
	print("Cleared save file!")
	_game_state = {
		"environments": {},
		"unlocked_plants": [],
		"current_environment": "",
		"study_progress": {}
	}
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	file.store_var(_game_state, true)

# Save the game state
func _save_game_to_file():
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		if debugging:
			print(_game_state)
		file.store_var(_game_state, true)
		file.close()
		print("Saved game data.")
	else:
		print("Failed to save: ", FileAccess.get_open_error())
		# Can add logic here to attempt and recover

# Load the game state
func _load_game_from_file():
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var new_game_state = file.get_var(true)
		if new_game_state:
			_game_state = new_game_state
			if debugging:
				print(_game_state)
			print("Loaded game data.")
		else:
			print("Failed to load game data!")
	else:
		print("Failed to load: ", FileAccess.get_open_error())

# Returns the dictionary of plants from the active environment
func get_plants():
	if _game_state.environments.has(_game_state.current_environment):
		return _game_state.environments[_game_state.current_environment].plants
	else:
		_game_state.environments[_game_state.current_environment] = {"plants": {}}
		return {}

# Returns the data associated with a plant name from the active environment
func get_plant_data_by_name(plant_name):
	return _game_state.environments[_game_state.current_environment].plants[plant_name]

# Returns the unlocked plants
func get_unlocked_plants():
	return _game_state.unlocked_plants

# Returns a boolean whether a plant is unlocked or not.
func is_plant_unlocked(plant_name):
	if plant_name in get_unlocked_plants():
		return true
	return false

# Private function to merge new plant data into the active environment's plant data
func _merge_new_plant_data(new_data: Dictionary):
	if not _game_state.environments.has(_game_state.current_environment):
		_game_state.environments[_game_state.current_environment] = {"plants": {}}
	_game_state.environments[_game_state.current_environment].plants.merge(new_data, true)
	_save_game_to_file.call_deferred()

# Update the game state when a plant is added
func update_plant(plant_node: BasePlant):
	if plant_node and not plant_node.is_inside_tree():
		return # Don't update plants that aren't in the environment!
	elif not plant_node:
		return
	var new_data = {
		plant_node.name: {
			"path": plant_node.get_plant_path(), 
			"pos": plant_node.global_position, 
			"rot": plant_node.rotation,
			"scale": plant_node.scale,
			"is_dead": plant_node.is_dead
		}
	}
	_merge_new_plant_data(new_data)

# Updates the study data, given progress
func update_study_data(progress):
	_game_state.study_progress = progress
	_save_game_to_file.call_deferred()

# Removes all study data (for when not studying)
func clear_study_data():
	_game_state.study_progress = {}
	_save_game_to_file.call_deferred()

# Get the study data
func get_study_data():
	return _game_state.study_progress

func get_studied_plant_name():
	if _game_state.study_progress != {}:
		return _game_state.study_progress.plant_name
	return ""

# Add a plant by name to the unlocked plants list
func add_unlocked_plant(plant_name: String):
	if plant_name not in _game_state.unlocked_plants:
		_game_state.unlocked_plants.append(plant_name)

func get_current_env():
	return 0
