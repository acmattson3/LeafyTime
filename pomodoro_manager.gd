extends Node

# Pomodoro Technique
var _pomodoro_study_remaining: float = pomodoro_interval - (pomodoro_interval/StudyManager.get_study_break_ratio())
var _pomodoro_break_remaining: float = pomodoro_interval/StudyManager.get_study_break_ratio()

# Uses 30-minute (default) time increments for study/breaks.
var pomodoro_interval: float = 30.0 * 60.0: # 30-minute intervals by default
	set(value):
		_pomodoro_study_remaining = value - (value/StudyManager.get_study_break_ratio())
		_pomodoro_break_remaining = value/StudyManager.get_study_break_ratio()
		pomodoro_interval = value
		
var use_pomodoro_reminders: bool = false

func get_use_pomodoro_reminders():
	return use_pomodoro_reminders

func set_pomodoro_interval(new_interval: float):
	pomodoro_interval = new_interval

func get_pomodoro_interval():
	return pomodoro_interval
