extends Node2D

var button_type = null

func _ready() -> void:
	$AudioStreamPlayer.play()

func _process(delta: float) -> void:
	pass

func _on_start_pressed() -> void:
	button_type = "start"
	$ColorRect.show()
	$ColorRect/fade_timer.start()
	$ColorRect/AnimationPlayer.play("fade_in")


func _on_options_pressed() -> void:
	button_type = "options"
	$ColorRect.show()
	$ColorRect/fade_timer.start()
	$ColorRect/AnimationPlayer.play("fade_in")

func _on_exit_pressed() -> void:
	button_type = "exit"
	$ColorRect.show()
	$ColorRect/fade_timer.start()
	$ColorRect/AnimationPlayer.play("fade_in")


func _on_fade_timer_timeout() -> void:
	if button_type == "start":
		get_tree().change_scene_to_file("res://scene/caves.tscn")
		$AudioStreamPlayer.stop()
	elif button_type == "options":
		get_tree().change_scene_to_file("res://scene/options.tscn")
	elif button_type == "exit":
		get_tree().quit()
