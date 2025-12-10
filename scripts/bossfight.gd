extends Node2D

func _ready() -> void:
	BackgroundMusic.stop()
	$AudioStreamPlayer.play()
	$Fade_transition.show()
	$Fade_transition/AnimationPlayer.play("fade_out")

func _process(delta: float) -> void:
	var boss = get_tree().get_nodes_in_group("inimigos")[0]
	if boss.get_pharaoh_morto():
		$AudioStreamPlayer.volume_db = -20
		$Levelend.monitoring = true
	else:
		$Levelend.monitoring = false
