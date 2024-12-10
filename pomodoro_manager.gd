extends Node

# PomodoroManager
# Handles Pomodoro timer logic and communicates with StudyManager for settings
# Emits signals for time updates and timer completions.

# Signals
signal study_time_up  # Emitted when study time ends
signal break_time_up  # Emitted when break time ends

# Internal variables for tracking time
var study_time_remaining: float = 0.0
var break_time_remaining: float = 0.0

enum PomoState { STUDY, BREAK, IDLE }
var active_timer: PomoState = PomoState.IDLE  # true or false for study or break, respectively

# Timer configuration
var study_to_break_ratio: float = 6.0  # Default ratio, updated from StudyManager
var interval_time: float = 30.0 * 60.0  # Default 30 minutes study time (in seconds)

func _ready():
	EventBus.load_game.connect(_on_load_game)

func _on_load_game():
	interval_time = GameManager.get_pomo_interval()
	var study_data = GameManager.get_study_data()
	if study_data == {}:
		return # No study info to be concerned about!
	start_study_timer(study_data.study_duration)

# Initialize timers based on the current study-to-break ratio
func setup_timers():
	study_to_break_ratio = StudyManager.get_study_break_ratio()
	break_time_remaining = interval_time / study_to_break_ratio
	study_time_remaining = interval_time - break_time_remaining

# Start the study timer
func start_study_timer(time: float):
	if active_timer == PomoState.STUDY:
		return  # Study timer already running
	setup_timers()
	if time < study_time_remaining:
		study_time_remaining = time
	active_timer = PomoState.STUDY
	SoundManager.play_happy()
	EventBus.show_info.emit("Time to study!")
	print("Pomodoro study timer started for ", seconds_to_readable_time(study_time_remaining))

# Start the break timer
func start_break_timer():
	if active_timer == PomoState.BREAK:
		return  # Break timer already running
	setup_timers()
	active_timer = PomoState.BREAK
	SoundManager.play_happy()
	EventBus.show_info.emit("Time for a break!")
	#print("Pomodoro break timer started for ", seconds_to_readable_time(break_time_remaining))

# Stop the current timer
func stop_timer():
	active_timer = PomoState.IDLE
	study_time_remaining = 0.0
	break_time_remaining = 0.0
	print("Pomodoro timer stopped.")

# Update timers each second
func _process(delta: float):
	if active_timer == PomoState.STUDY:
		study_time_remaining -= delta
		if study_time_remaining <= 0.0:
			active_timer = PomoState.IDLE
			print("Pomodoro study time up!")
			study_time_up.emit()

	elif active_timer == PomoState.BREAK:
		break_time_remaining -= delta
		if break_time_remaining <= 0.0:
			active_timer = PomoState.IDLE
			print("Pomodoro break time up!")
			break_time_up.emit()

# Convert seconds to HH:MM:SS format
func seconds_to_readable_time(time_in_sec):
	if time_in_sec is float:
		time_in_sec = int(time_in_sec)
	var seconds = time_in_sec % 60
	var minutes = (time_in_sec / 60) % 60
	var hours = (time_in_sec / 60) / 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

# Return the time remaining for the active timer
func get_time_remaining():
	if active_timer == PomoState.STUDY:
		return study_time_remaining
	elif active_timer == PomoState.BREAK:
		return break_time_remaining
	return 0.0

# Update the study-to-break ratio dynamically (optional)
func update_study_break_ratio(new_ratio: float):
	study_to_break_ratio = new_ratio if new_ratio > 0 else 6.0
	setup_timers()
	print("Updated study-to-break ratio to ", study_to_break_ratio)

func set_interval_time(value: float):
	interval_time = value
	GameManager.set_pomo_interval(value)
