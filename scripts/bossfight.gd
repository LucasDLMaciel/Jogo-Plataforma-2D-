extends Node2D

func _ready() -> void:
	BackgroundMusic.stop()
	$AudioStreamPlayer.play()
	$Fade_transition.show()
	$Fade_transition/AnimationPlayer.play("fade_out")
