@tool
extends StaticBody3D
class_name BasePlant # The base class for all plants

var is_dead: bool = false
@export var unlocked: bool = false
@export var plant_name: String = "Plant" # The plant's name

# Study time is currently limited to 11 hours, 59 minutes, and 59.99 seconds (~12 hours)
@export_range(0, 11) var study_hours: int = 0: # The number of hours to grow this plant
	set(value):
		study_hours = clamp(value, 0, 11)
		_set_study_duration()
@export_range(0, 59) var study_minutes: int = 0: # The number of minutes to grow this plant
	set(value):
		study_minutes = clamp(value, 0, 59)
		_set_study_duration()
@export_range(0.0, 59.99) var study_seconds: float = 0.0: # The number of seconds to grow this plant
	set(value):
		study_seconds = clamp(value, 0.0, 59.99)
		_set_study_duration()

var _study_duration: float = 0.0 # The total time in seconds to grow this plant

# Calculate and set study_duration based on study_hours, study_minutes, and study_seconds
func _set_study_duration():
	var hours_to_seconds = float(study_hours) * 3600.0
	var minutes_to_seconds = float(study_minutes) * 60.0
	_study_duration = hours_to_seconds + minutes_to_seconds + study_seconds

# Returns the study duration in seconds
func get_study_duration():
	return _study_duration

func get_readable_study_duration():
	var duration_string = ""
	if study_hours > 0:
		duration_string += str(study_hours) + "h "
	if study_minutes > 0:
		duration_string += str(study_minutes) + "m "
	if study_seconds > 0.0:
		duration_string += str(round(study_seconds)) + "s"
	
	if duration_string == "":
		duration_string = "Instant"
	return duration_string

func get_unlocked():
	return unlocked

# Virtual function for all plants.
# Returns the current plant's scene path.
func get_plant_path():
	return ""

func get_plant_name():
	return plant_name

# Virtual function for all plants.
# Controls whether we can collide with the plant.
func set_shape_interact(_is_enabled := true):
	pass
