@tool
extends Node3D
# MovableCamera3D
# Using left click, move the camera around the origin
# Using mouse wheel, zoom camera in and out.

@export var cam_v_max := 75.0 # Max vertical camera angle (lower bound)
@export var cam_v_min := -75.0 # Min vertical camera angle (upper bound)
@export var h_sens = 0.1 # Horizontal sensitivity
@export var v_sens = 0.1 # Vertical sensitivity
@export var do_interpolate := true # Do we interpolate camera movement?
var h_accel = 10
var v_accel = 10
@onready var cam_h = $Horizontal
@onready var cam_v = $Horizontal/Vertical

@onready var cam = $Horizontal/Vertical/Camera3D

@export var do_right_click_motion = true

@export var min_distance = 3.0
@export var max_distance = 240.0
var set_cam_dist := true
@export var camera_distance: float = 120.0: # Distance of camera from rotation origin
	set(value):
		camera_distance = value
		if max_distance != null and min_distance != null:
			if value > max_distance:
				value = max_distance
			elif value < min_distance:
				value = min_distance
			camera_distance = clamp(value, min_distance, max_distance)
		if cam:
			cam.position.z = value
		else:
			set_cam_dist = false
@export_range(1.0, 100.0) var zoom_sens: float = 2.5 # Zoom sensitivity

var cam_rot_updated := true
@export_range(-179.99, 180.0) var camrot_h: float = 0.0:
	set(value):
		if Engine.is_editor_hint():
			if cam_h:
				cam_h.rotation_degrees.y = value
			else:
				cam_rot_updated = false
		camrot_h = value
@export_range(-89.99, 90.0) var camrot_v: float = 0.0:
	set(value):
		if Engine.is_editor_hint():
			if cam_v:
				cam_v.rotation_degrees.x = value
			else:
				cam_rot_updated = false
		camrot_v = clamp(value, -cam_v_max, -cam_v_min)

var can_input: bool = true # Can the camera be moved?
@export var lock_horiz: bool = false # Lock horizontal rotation (vertical only)
@export var can_zoom: bool = true # Can we zoom?

func toggle_inputs(in_bool = null):
	if in_bool == null:
		can_input = !can_input
	else:
		can_input = in_bool

func _input(event):
	if Engine.is_editor_hint():
		return # Don't run this in the editor!
	if can_input and event is InputEventMouseMotion:
		if Input.is_action_pressed("right_click") or not do_right_click_motion:
			camrot_h -= event.relative.x * h_sens
			camrot_v -= event.relative.y * v_sens

func _ready():
	if Engine.is_editor_hint() and not cam_rot_updated:
		camrot_v = camrot_v
		camrot_h = camrot_h
		cam_rot_updated = true
	if not set_cam_dist:
		camera_distance = camera_distance
		set_cam_dist = true
	cam_h.rotation_degrees.y = camrot_h
	cam_v.rotation_degrees.x = camrot_v

const SENS_MULT = 5
func _physics_process(delta):
	if Engine.is_editor_hint():
		return # Don't run this in the editor!
	if can_input:
		if can_zoom:
			if Input.is_action_just_pressed("zoom_in"):
				camera_distance = lerp(camera_distance, camera_distance-0.5*zoom_sens, delta*h_accel)
			elif Input.is_action_just_pressed("zoom_out"):
				camera_distance = lerp(camera_distance, camera_distance+0.5*zoom_sens, delta*h_accel)
		if Input.is_action_pressed("pan_down"):
			camrot_v -= v_sens * SENS_MULT
		if Input.is_action_pressed("pan_up"):
			camrot_v += v_sens * SENS_MULT
		if Input.is_action_pressed("pan_left"):
			camrot_h -= h_sens * SENS_MULT
		if Input.is_action_pressed("pan_right"):
			camrot_h += h_sens * SENS_MULT
	
	# Camera movement logic
	if do_interpolate:
		cam_v.rotation_degrees.x = lerp(cam_v.rotation_degrees.x, camrot_v, delta * v_accel)
		if not lock_horiz:
			cam_h.rotation_degrees.y = lerp(cam_h.rotation_degrees.y, camrot_h, delta * h_accel)
	else:
		cam_v.rotation_degrees.x = camrot_v * delta * 150
		if not lock_horiz:
			cam_h.rotation_degrees.y = camrot_h * delta * 150
