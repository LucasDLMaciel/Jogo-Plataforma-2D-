extends Area2D

@export var next_level = ""

func _on_body_entered(_body: Node2D) -> void:
	call_deferred("load_next_scene")

func load_next_scene():
	var trans = get_tree().get_nodes_in_group("transição")[0]
	trans.show()
	trans.get_child(0).play("fade_in")
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scene/" + next_level + ".tscn")
