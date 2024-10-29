extends Node
# StudyManager
# Handles study logic, including:
#   * Timers
#     * Study time
#     * Breaks
#     * Plant growth
#   * Study states
#     * Actively studying
#     * On break
#     * Failed studying

enum StudyState { IDLE, ACTIVE, ON_BREAK }
var state := StudyState.IDLE

@onready var active_plant: BasePlant = null # The plant we are growing by studying
@onready var study_start_time: float = 0 # To check for exiting program
@onready var study_time_remaining: float = 0.0
@onready var break_time_remaining: float = 0.0

var study_to_break_ratio: float = 6.0 # minutes of study time for every minute of break time

func _ready():
	EventBus.start_study_session.connect(_on_start_study_session)
	EventBus.start_break.connect(_on_start_break)
	EventBus.resume_study_session.connect(_on_resume_study_session)
	EventBus.stop_study_session.connect(_on_stop_study_session)
	EventBus.load_game.connect(_on_load_game)

func _on_load_game():
	var study_data = GameManager.get_study_data()
	if study_data == {}:
		return # No study info to be concerned about!
	
	EventBus.resume_study_after_exit.emit()
	state = StudyState.ON_BREAK # Leave off on a break
	var time_diff = study_data.start_time - Time.get_unix_time_from_system()
	if time_diff > study_data.break_duration: # Exited for longer than break time!
		EventBus.stop_study_session.emit(false)
	else: # Exited for less than break time
		break_time_remaining = study_data.break_duration - time_diff
		study_time_remaining = study_data.study_duration
		study_start_time = study_data.start_time

func set_active_plant(plant: BasePlant):
	active_plant = plant

func _process(delta):
	if state == StudyState.ACTIVE:
		study_time_remaining -= delta
		if study_time_remaining <= 0.0: # Done studying!
			EventBus.stop_study_session.emit(true)
	elif state == StudyState.ON_BREAK:
		break_time_remaining -= delta
		if study_time_remaining <= 0.0: # Out of break time!
			EventBus.stop_study_session.emit(false)

# Handler for starting a study session
func _on_start_study_session(plant: BasePlant):
	active_plant = plant
	
	# Set up total study and break times
	var total_plant_time = plant.get_study_duration()
	break_time_remaining = total_plant_time / study_to_break_ratio
	study_time_remaining = total_plant_time - break_time_remaining
	
	state = StudyState.ACTIVE
	study_start_time = Time.get_unix_time_from_system()
	print("Studying started for ", plant.get_plant_name(), " (", plant.get_readable_study_duration(), ")")

# Handler for starting a break
func _on_start_break():
	if state == StudyState.ACTIVE:
		state = StudyState.ON_BREAK
		print("Studying paused.")

# Handler for resuming a paused study session
func _on_resume_study_session():
	if state == StudyState.ON_BREAK:
		state = StudyState.ACTIVE
		print("Studying resumed!")

# Handler for stopping a study session
func _on_stop_study_session(completed: bool):
	if state == StudyState.ACTIVE or state == StudyState.ON_BREAK:
		print("Studying stopped!")
		if completed: # Succeeded!
			state = StudyState.IDLE
			active_plant = null
			_save_study_progress()
		else: # Failed!
			state = StudyState.IDLE
			active_plant.is_dead = true
			active_plant = null
			_save_study_progress()

# Save current progress to file through GameManager
func _save_study_progress():
	if active_plant:
		var progress = {
			"plant_name": active_plant.get_plant_name(),
			"break_duration": break_time_remaining,
			"study_duration": study_time_remaining,
			"start_time": study_start_time
		}
		GameManager.update_study_data(progress)
	else: # We must not be studying!
		GameManager.clear_study_data()

func get_time_remaining():
	match state:
		StudyState.ACTIVE:
			return study_time_remaining
		StudyState.ON_BREAK:
			return break_time_remaining
	return 0.0
