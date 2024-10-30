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
@onready var starting_study_time: float = 0.0 # The study time we started with
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
	print("User stopped during study session!")
	EventBus.resume_study_after_exit.emit(study_data.plant_name)
	await get_tree().physics_frame
	state = StudyState.ON_BREAK # Leave off on a break
	var time_diff = Time.get_unix_time_from_system() - study_data.exit_time
	if time_diff > study_data.break_duration: # Exited for longer than break time!
		print("User was gone ", time_diff - study_data.break_duration, " seconds too long!")
		var warning_message = "You exited the game while studying, and "
		warning_message += "went " + str(int(time_diff - study_data.break_duration)) + " over "
		warning_message += "your total break time. You have failed your study session."
		EventBus.show_warning.emit(warning_message)
		EventBus.stop_study_session.emit(false)
	else: # Exited for less than break time
		print("User lost ", int(time_diff), " seconds of break time!")
		var warning_message = "You exited the game while studying, and "
		warning_message += "lost "+str(int(time_diff))+" seconds of break time! "
		warning_message += "You are currently using break time."
		EventBus.show_warning.emit(warning_message)
		break_time_remaining = study_data.break_duration - time_diff
		study_time_remaining = study_data.study_duration
		starting_study_time = study_data.starting_study_time

func set_active_plant(plant: BasePlant):
	active_plant = plant

func _physics_process(_delta):
	if active_plant and state == StudyState.ACTIVE:
		var ratio = (starting_study_time-study_time_remaining)/starting_study_time
		ratio = 0.01 if ratio <= 0.0 else ratio
		active_plant.scale = Vector3(ratio,ratio,ratio)

#var save_elapsed = 0.0
#var save_interval = 1.0
func _process(delta):
	if state == StudyState.ACTIVE:
		study_time_remaining -= delta
		if study_time_remaining <= 0.0: # Done studying!
			EventBus.stop_study_session.emit(true)
	elif state == StudyState.ON_BREAK:
		break_time_remaining -= delta
		if break_time_remaining <= 0.0: # Out of break time!
			EventBus.stop_study_session.emit(false)
	#save_elapsed += delta
	#if save_elapsed > save_interval and is_studying():
		#save_elapsed = 0.0
		#_save_study_progress()

func _notification(what):
	# Catch pressing X on the application window
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_studying():
			_save_study_progress()
			GameManager.update_plant(active_plant)
		await get_tree().physics_frame

# Handler for starting a study session
func _on_start_study_session(plant: BasePlant):
	active_plant = plant
	
	# Set up total study and break times
	var total_plant_time = plant.get_study_duration()
	break_time_remaining = total_plant_time / study_to_break_ratio
	study_time_remaining = total_plant_time - break_time_remaining
	starting_study_time = study_time_remaining
	
	state = StudyState.ACTIVE
	print(plant.get_readable_study_duration(), "study session started for ", plant.get_plant_name())

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
			print("Study session completed!")
			state = StudyState.IDLE
			EventBus.unlock_plant.emit(active_plant.plant_name)
			active_plant = null
			_save_study_progress()
		else: # Failed!
			print("Study session incomplete.")
			state = StudyState.IDLE
			if active_plant:
				active_plant.is_dead = true
				GameManager.update_plant(active_plant)
				active_plant = null
			else:
				print("No active plant!")
			_save_study_progress()

# Save current progress to file through GameManager
func _save_study_progress():
	if active_plant:
		var plant_name = active_plant.name
		var progress = {
			"plant_name": plant_name,
			"break_duration": break_time_remaining,
			"study_duration": study_time_remaining,
			"starting_study_time": starting_study_time,
			"exit_time": Time.get_unix_time_from_system()
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

# Code by Felipe (https://forum.godotengine.org/t/how-to-convert-seconds-into-ddmm-ss-format/8174)
func seconds_to_readable_time(time_in_sec):
	if time_in_sec is float:
		time_in_sec = int(time_in_sec)
	var seconds = time_in_sec%60
	var minutes = (time_in_sec/60)%60
	var hours = (time_in_sec/60)/60
	
	#returns a string with the format "HH:MM:SS"
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

func get_readable_time_remaining():
	return seconds_to_readable_time(get_time_remaining())

# Return true if a study session is in progress.
func is_studying():
	match state:
		StudyState.ACTIVE, StudyState.ON_BREAK:
			return true
		_:
			return false

# Return true if the user is on a break
func is_on_break():
	if state == StudyState.ON_BREAK:
		return true
	return false
