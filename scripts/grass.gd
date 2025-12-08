extends Node2D

func _ready() -> void:
	BackgroundMusic.stop()
	$AudioStreamPlayer.play()
	$Fade_transition.show()
	$Fade_transition/AnimationPlayer.play("fade_out")

func _process(delta: float) -> void:
	var monge = get_tree().get_nodes_in_group("inimigos")[0]
	if monge.get_monge_morto():
		$AudioStreamPlayer.stop()
