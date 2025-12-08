extends Node2D

func _ready() -> void:
	if !BackgroundMusic.playing:
		BackgroundMusic.play()
	$Fade_transition.show()
	$Fade_transition/AnimationPlayer.play("fade_out")
