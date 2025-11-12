extends AudioStreamPlayer

func _ready() -> void:
	var cena = get_tree().tree_changed
	if cena: 
		play()
