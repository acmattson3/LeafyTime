extends Node

@onready var player: AudioStreamPlayer

var very_happy: AudioStreamWAV = load("res://util/sounds/very_happy.wav")
var happy: AudioStreamWAV = load("res://util/sounds/happy.wav")
var neutral: AudioStreamWAV = load("res://util/sounds/neutral.wav")
var sad: AudioStreamWAV = load("res://util/sounds/sad.wav")
var very_sad: AudioStreamWAV = load("res://util/sounds/very_sad.wav")

func _ready():
	player = AudioStreamPlayer.new()
	get_tree().root.add_child.call_deferred(player)

func play(sound: String):
	match sound:
		"very_happy":
			play_very_happy()
		"happy":
			play_happy()
		"neutral":
			play_neutral()
		"sad":
			play_sad()
		"very_sad":
			play_very_sad()

func play_very_happy():
	player.stream = very_happy
	player.play()

func play_happy():
	player.stream = happy
	player.play()

func play_neutral():
	player.stream = neutral
	player.play()

func play_sad():
	player.stream = sad
	player.play()

func play_very_sad():
	player.stream = very_sad
	player.play()
