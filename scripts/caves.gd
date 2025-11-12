extends Node2D
@onready var camera: Camera2D = $Camera


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !BackgroundMusic.playing:
		BackgroundMusic.play()
