extends Node2D
@onready var camera: Camera2D = $Camera


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera.screen_shake(8, 5)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
