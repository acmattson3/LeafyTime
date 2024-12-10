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
@onready var total_time_remaining: float = 0.0

var using_pomodoro: bool = true # Are we using Pomodoro logic?

# Window tracking logic
var whitelist: bool = false: # False == blacklist, True == whitelist
	set(value):
		GameManager.set_do_whitelist(value)
		whitelist = value
var _focus_greylist: Array = []: # The list of blocked/allowed keywords
	set(value):
		GameManager.set_greylist(value)
		_focus_greylist = value

var _study_to_break_ratio: float = 6.0: # minutes of study time for every minute of break time
	set(value):
		GameManager.set_study_break_ratio(value)
		_study_to_break_ratio = value

func set_study_break_ratio(new_ratio: float):
	_study_to_break_ratio = new_ratio if new_ratio > 0 else 6.0

func get_study_break_ratio():
	return _study_to_break_ratio

func _ready():
	EventBus.start_study_session.connect(_on_start_study_session)
	EventBus.start_break.connect(_on_start_break)
	EventBus.resume_study_session.connect(_on_resume_study_session)
	EventBus.stop_study_session.connect(_on_stop_study_session)
	EventBus.load_game.connect(_on_load_game)
	
	PomodoroManager.study_time_up.connect(_on_start_break)
	PomodoroManager.break_time_up.connect(_on_resume_study_session)

func _on_load_game():
	_focus_greylist = GameManager.get_greylist()
	whitelist = GameManager.get_do_whitelist()
	_study_to_break_ratio = GameManager.get_study_break_ratio()
	using_pomodoro = GameManager.get_use_pomodoro()
	
	var study_data = GameManager.get_study_data()
	if study_data == {}:
		return # No study info to be concerned about!
	print("User stopped during study session!")
	EventBus.resume_study_after_exit.emit(study_data.plant_name)
	await get_tree().physics_frame
	var time_diff = Time.get_unix_time_from_system() - study_data.exit_time
	if using_pomodoro:
		state = StudyState.ACTIVE
		study_time_remaining = study_data.study_duration
		starting_study_time = study_data.starting_study_time
		if time_diff > max_off_task:
			var warning_message = "You exited the game while studying, and "
			warning_message += "were absent for more than 30 seconds! You "
			warning_message += "have failed your study session."
			EventBus.show_warning.emit(warning_message)
			EventBus.stop_study_session.emit(false)
		else:
			SoundManager.play_neutral()
			var warning_message = "You exited the game while studying, but "
			warning_message += "you were absent for less than 30 seconds. "
			warning_message += "Your study session has been resumed."
			EventBus.show_warning.emit(warning_message)
		return
	state = StudyState.ON_BREAK # Leave off on a break
	if time_diff > study_data.break_duration: # Exited for longer than break time!
		#SoundManager.play_sad()
		print("User was gone ", time_diff - study_data.break_duration, " seconds too long!")
		var warning_message = "You exited the game while studying, and "
		warning_message += "went " + str(int(time_diff - study_data.break_duration)) + " seconds over "
		warning_message += "your total break time. You have failed your study session."
		EventBus.show_warning.emit(warning_message)
		EventBus.stop_study_session.emit(false)
	else: # Exited for less than break time
		print("User lost ", int(time_diff), " seconds of break time!")
		SoundManager.play_sad()
		var warning_message = "You exited the game while studying, and "
		warning_message += "lost "+str(int(time_diff))+" seconds of break time! "
		warning_message += "You are currently using break time."
		EventBus.show_warning.emit(warning_message)
		break_time_remaining = study_data.break_duration - time_diff
		study_time_remaining = study_data.study_duration
		starting_study_time = study_data.starting_study_time

func set_active_plant(plant: BasePlant):
	active_plant = plant

var scale_ratio = 1.0
func _physics_process(_delta):
	if active_plant and state == StudyState.ACTIVE:
		var ratio = scale_ratio*(starting_study_time-study_time_remaining)/starting_study_time
		ratio = 0.01 if ratio <= 0.0 else ratio
		active_plant.scale = Vector3(ratio,ratio,ratio)

var check_focus_elapsed: float  = 25.0
var check_focus_interval: float = 5.0 # Check focus every 5 seconds
var reminded: bool = false
var off_task_countdown: bool = false
var off_task_elapsed: float = 0.0
var max_off_task: float = 30.0
func _process(delta):
	total_time_remaining = break_time_remaining + study_time_remaining
	if total_time_remaining < 0.0:
		EventBus.stop_study_session.emit(true)
	
	if off_task_countdown:
		if state == StudyState.ON_BREAK: # Break time has begun
			off_task_elapsed = 0.0
			off_task_countdown = false
		check_focus_elapsed += delta
		off_task_elapsed += delta
		if off_task_elapsed > max_off_task:
			off_task_elapsed = 0.0
			off_task_countdown = false
			EventBus.show_warning.emit("You remained distracted, and your plant died!")
			EventBus.stop_study_session.emit(false)
		
		if check_focus_elapsed > 1.0:
			check_focus_elapsed = 0.0
			if not check_distracted(): # No longer distracted
				off_task_elapsed = 0.0
				off_task_countdown = false
				SoundManager.play_happy()
				EventBus.show_info.emit("Good job getting back on task!")
	
	if state == StudyState.ACTIVE:
		reminded = false
		study_time_remaining -= delta
		check_focus_elapsed += delta
		
		if study_time_remaining <= 0.0: # Done studying!
			EventBus.stop_study_session.emit(true)
		if check_focus_elapsed >= check_focus_interval:
			if check_distracted():
				print("User is distracted!")
				var warning_message = "According to your list of apps, "
				warning_message += "you are distracted! You have "
				if not using_pomodoro:
					warning_message += "been kicked into break time."
					EventBus.start_break.emit()
				else:
					warning_message += " 30 seconds to get back on task."
					off_task_countdown = true
					off_task_elapsed = 0.0
				SoundManager.play_sad()
				EventBus.show_warning.emit(warning_message)
			check_focus_elapsed = 0.0
		
	elif state == StudyState.ON_BREAK:
		break_time_remaining -= delta
		if using_pomodoro:
			return # We don't care; PomodoroManager handles it!
		if break_time_remaining < 30.0 and not reminded:
			reminded = true
			EventBus.show_warning.emit("You are almost out of break time!")
			SoundManager.play_sad()
		if break_time_remaining <= 0.0: # Out of break time!
			EventBus.stop_study_session.emit(false)
			EventBus.show_warning.emit("You ran out of break time, and your plant died!")

func get_readable_total_time_remaining():
	return seconds_to_readable_time(total_time_remaining)

# Check if a user violates the black/whitelist
func check_distracted():
	var tracker := WindowTracker.new()
	if whitelist: # Every window must include something from greylist
		for window in tracker.get_open_windows():
			var window_passed: bool = false
			for item in _focus_greylist:
				if item in window:
					window_passed = true
					break # We're good!
			if not window_passed:
				return true # We're distracted!
	else: # All windows must not include anything from greylist
		for window in tracker.get_open_windows():
			for item in _focus_greylist:
				if item in window:
					return true # We're distracted!
	return false

func _notification(what):
	# Catch pressing X on the application window
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_study_progress()
		if is_studying():
			GameManager.update_plant(active_plant)
		await get_tree().physics_frame

# Handler for starting a study session
func _on_start_study_session(plant: BasePlant):
	if state == StudyState.ACTIVE or state == StudyState.ON_BREAK:
		return # We are already studying; don't do that!
	scale_ratio = randf_range(0.8,1.2)
	SoundManager.play_happy()
	active_plant = plant
	
	# Set up total study and break times
	var total_plant_time = plant.get_study_duration()
	break_time_remaining = total_plant_time / _study_to_break_ratio
	study_time_remaining = total_plant_time - break_time_remaining
	starting_study_time = study_time_remaining
	
	if using_pomodoro:
		PomodoroManager.start_study_timer(study_time_remaining)
	
	state = StudyState.ACTIVE
	print(plant.get_readable_study_duration(), " study session started for ", plant.get_plant_name())

# Handler for starting a break
func _on_start_break():
	if state == StudyState.ACTIVE:
		if using_pomodoro:
			PomodoroManager.start_break_timer()
		state = StudyState.ON_BREAK
		print("Studying paused.")

# Handler for resuming a paused study session
func _on_resume_study_session():
	if state == StudyState.ON_BREAK:
		if using_pomodoro:
			PomodoroManager.start_study_timer(study_time_remaining)
		state = StudyState.ACTIVE
		print("Studying resumed!")

# Handler for stopping a study session
func _on_stop_study_session(completed: bool):
	if state == StudyState.ACTIVE or state == StudyState.ON_BREAK:
		if using_pomodoro:
			PomodoroManager.stop_timer()
		print("Studying stopped!")
		if completed: # Succeeded!
			SoundManager.play_very_happy()
			print("Study session completed!")
			state = StudyState.IDLE
			active_plant.scale = Vector3(scale_ratio,scale_ratio,scale_ratio)
			EventBus.unlock_plant.emit(active_plant.plant_name)
			GameManager.update_plant(active_plant)
			EventBus.show_info.emit("You successfully got a "+active_plant.plant_name+"!")
			active_plant = null
			_save_study_progress()
		else: # Failed!
			SoundManager.play_very_sad()
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
	if state != StudyState.IDLE:
		var plant_name = ""
		if active_plant:
			plant_name = active_plant.name
		var progress = {
			"plant_name": plant_name,
			"break_duration": break_time_remaining,
			"study_duration": study_time_remaining,
			"starting_study_time": starting_study_time,
			"exit_time": Time.get_unix_time_from_system()
		}
		GameManager.update_study_data(progress)
	else: # We must not be studying!
		print("Clearing study data!")
		GameManager.clear_study_data()

func get_time_remaining():
	if using_pomodoro:
		return PomodoroManager.get_time_remaining()
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

func get_active_plant():
	return active_plant

func set_greylist(words: Array):
	_focus_greylist = []
	for word in words:
		_focus_greylist.append(word)
