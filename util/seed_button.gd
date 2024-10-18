@tool
extends PanelContainer
class_name SeedButton

signal seed_button_down(seed_button)
signal seed_button_up(seed_button)

# The plant/seed this button corresponds to
# We will want some way to show a preview of the full-grown plant to users.
#   * If our plant scene has different meshes it switches between at growth
#     stages, we could just make sure that our plants reference a full-grown
#     state in code so that we can (for preview purposes) make that visible.
#   * We would want some way for the plant scenes to know that they are just
#     being previewed (i.e., even though you're loaded, don't start any logic!).
#     This may already be handled by a global event script (one plant at a time,
#     the growth only begins upon planting, all logic handled by event script based
#     on data from plant scene; it controls the plant scene, and the plant scene
#     just provides helper functions for control). 
@onready var button = $Button

@export var plant_scene: PackedScene
var has_set_icon: bool = true
@export var plant_icon: CompressedTexture2D = load("res://icon.svg"):
	set(value):
		if value:
			if button:
				button.icon = value
			else:
				has_set_icon = false
		plant_icon = value

var snap_position: bool = false
var prev_pos := Vector2.ZERO
var not_reset: bool = false

func _ready():
	prev_pos = button.global_position
	if not has_set_icon:
		plant_icon = plant_icon

func _on_button_button_down() -> void:
	seed_button_down.emit(self)
	prev_pos = button.global_position
	snap_position = true

func _on_button_button_up() -> void:
	make_transparent(false)
	seed_button_up.emit(self)
	snap_position = false
	not_reset = true

func make_transparent(do_transparent: bool):
	if do_transparent:
		button.self_modulate.a = 0.25
	else:
		button.self_modulate.a = 1.0

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if snap_position:
		button.global_position = get_global_mouse_position() - size/2.0
	elif not_reset:
		button.global_position = prev_pos
		not_reset = false
