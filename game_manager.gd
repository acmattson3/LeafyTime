extends Node
# GameManager
# Handles game states (saving/loading)

var _game_state := {
	"environments": {},
	"unlocked_plants": [],
	"current_environment": ""
}
var done_emit_load := false

func _ready():
	_load_game_from_file()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_game_to_file()
		get_tree().quit() # default behavior

func _process(_delta):
	if not done_emit_load:
		EventBus.load_game.emit()
		done_emit_load = true
	if Input.is_key_pressed(KEY_F1) and Input.is_key_pressed(KEY_CTRL) and Input.is_key_pressed(KEY_ALT):
		print("Cleared save file!")
		_game_state = {
			"environments": {},
			"unlocked_plants": [],
			"current_environment": ""
		}
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
		file.store_var(_game_state, true)

const SAVE_FILE_PATH = "user://save_game.json"
# Save the game state
func _save_game_to_file():
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		print("Saving data...")
		file.store_var(_game_state, true)
		#file.store_string(JSON.stringify(_game_state))
		file.close()
	else:
		print("Failed to save: ", file.get_open_error())
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
		print("Failed to save: ", file.get_open_error())

func get_plants_in_env(env_id):
	if _game_state.environments.has(env_id):
		return _game_state.environments[env_id].plants
	else:
		_game_state.environments[env_id] = {"plants": {}}
		return {}

func _merge_new_plant_data(env_id: int, new_data: Dictionary):
	_game_state.environments[env_id].plants.merge(new_data, true)
	_save_game_to_file.call_deferred()

# Update the game state when a plant is added or moved
# Takes an environment ID and a plant node
func update_plant_in_environment(env_id: int, plant_node: BasePlant):
	var plant_path = plant_node.get_plant_path()
	var plant_pos = plant_node.global_position
	var plant_rot = plant_node.rotation
	var plant_dead = plant_node.is_dead
	var new_data = {
		plant_node.name: {
			"path": plant_path, 
			"pos": plant_pos, 
			"rot": plant_rot,
			"is_dead": plant_dead
		}
	}
	_merge_new_plant_data(env_id, new_data)
