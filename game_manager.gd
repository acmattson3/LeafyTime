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
#    ... More game state data here
#   } # End game state
var _game_state := {
	"environments": {},
	"unlocked_plants": [], # Requires that all plants have unique names
	"current_environment": 0 # The last loaded environment
}
const SAVE_FILE_PATH = "user://save_game.json"

var done_emit_load := false # Have we finished emitting EventBus.load_game?

func _ready():
	_load_game_from_file() # Load data on startup

func _notification(what):
	# Catch pressing X on the application window
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_game_to_file() # Save before we close!
		get_tree().quit() # Do the default behavior too

func _process(_delta):
	if not done_emit_load:
		EventBus.load_game.emit()
		done_emit_load = true
	# Debugging keyboard shortcut to clear the game save file (likely removed later)
	if Input.is_key_pressed(KEY_F1) and Input.is_key_pressed(KEY_CTRL) and Input.is_key_pressed(KEY_ALT):
		print("Cleared save file!")
		_game_state = {
			"environments": {},
			"unlocked_plants": [],
			"current_environment": ""
		}
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
		file.store_var(_game_state, true)

# Save the game state
func _save_game_to_file():
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		print("Saving data...")
		file.store_var(_game_state, true)
		file.close()
	else:
		print("Failed to save: ", FileAccess.get_open_error())
		# Can add logic here to attempt and recover

# Load the game state
func _load_game_from_file():
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var new_game_state = file.get_var(true)
		if new_game_state:
			print("Loaded save data.")
			_game_state = new_game_state
		else:
			print("Failed to load game data!")
	else:
		print("Failed to save: ", FileAccess.get_open_error())

# Returns the dictionary of plants from an environment given its ID
func get_plants_in_env(env_id):
	if _game_state.environments.has(env_id):
		return _game_state.environments[env_id].plants
	else:
		_game_state.environments[env_id] = {"plants": {}}
		return {}

# Private function to merge new plant data into an environment's plant data
func _merge_new_plant_data(env_id: int, new_data: Dictionary):
	if not _game_state.environments.has(env_id):
		_game_state.environments[env_id] = {"plants": {}}
	_game_state.environments[env_id].plants.merge(new_data, true)
	_save_game_to_file.call_deferred()

# Update the game state when a plant is added or moved
# Takes an environment ID and a plant node
func update_plant_in_environment(env_id: int, plant_node: BasePlant):
	var new_data = {
		plant_node.name: {
			"path": plant_node.get_plant_path(), 
			"pos": plant_node.global_position, 
			"rot": plant_node.rotation,
			"is_dead": plant_node.is_dead,
			"is_unlocked": plant_node.unlocked
		}
	}
	_merge_new_plant_data(env_id, new_data)
