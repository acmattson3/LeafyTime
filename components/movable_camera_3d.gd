@tool
extends Node3D
# MovableCamera3D
# Using left click, move the camera around the origin
# Using mouse wheel, zoom camera in and out.

const cam_v_max := 75.0 # Max vertical camera angle (lower bound)
const cam_v_min := -75.0 # Min vertical camera angle (upper bound)
@onready var h_sens = 0.1 # Horizontal sensitivity
@onready var v_sens = 0.1 # Vertical sensitivity
var h_accel = 10
var v_accel = 10
@onready var cam_h = $Horizontal
@onready var cam_v = $Horizontal/Vertical

@onready var cam = $Horizontal/Vertical/Camera3D

var set_cam_dist := true
@export_range(45.0, 240.0) var camera_distance: float = 120.0: # Distance of camera from rotation origin
	set(value):
		if value > 240.0:
			value = 240.0
		elif value < 45.0:
			value = 45.0
		if cam:
			cam.position.z = value
		else:
			set_cam_dist = false
		camera_distance = value
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
@export_range(cam_v_min, cam_v_max) var camrot_v: float = 0.0:
	set(value):
		if Engine.is_editor_hint():
			if cam_v:
				cam_v.rotation_degrees.x = value
			else:
				cam_rot_updated = false
		camrot_v = value

var can_input: bool = true # Can the camera be moved?
var lock_horiz: bool = false # Lock horizontal rotation (vertical only)

func toggle_inputs(in_bool = null):
	if in_bool == null:
		can_input = !can_input
	else:
		can_input = in_bool

func _input(event):
	if Engine.is_editor_hint():
		return # Don't run this in the editor!
	if can_input and event is InputEventMouseMotion:
		if Input.is_action_pressed("right_click"):
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

const SENS_MULT = 5
func _physics_process(delta):
	if Engine.is_editor_hint():
		return # Don't run this in the editor!
	if can_input:
		if Input.is_action_pressed("right_click"):
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
	camrot_v = clamp(camrot_v, cam_v_min, cam_v_max)
	if not lock_horiz:
		cam_h.rotation_degrees.y = lerp(cam_h.rotation_degrees.y, camrot_h, delta * h_accel)
	cam_v.rotation_degrees.x = lerp(cam_v.rotation_degrees.x, camrot_v, delta * v_accel)
