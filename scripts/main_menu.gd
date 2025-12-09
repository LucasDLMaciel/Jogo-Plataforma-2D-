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
	$Menu_click.play()

func _on_exit_pressed() -> void:
	button_type = "exit"
	$ColorRect.show()
	$ColorRect/fade_timer.start()
	$ColorRect/AnimationPlayer.play("fade_in")
	$Menu_click.play()

func _on_controls_pressed() -> void:
	$ButtonManager.hide()
	$Controles.show()
	$Controles/MarginContainer/ScrollContainer/VBoxContainer/Sair.grab_focus()
	$Menu_click.play()

func _on_sair_pressed() -> void:
	$ButtonManager.show()
	$Controles.hide()
	$ButtonManager/Controls.grab_focus()
	$Menu_click.play()

func _on_fade_timer_timeout() -> void:
	if button_type == "start":
		get_tree().change_scene_to_file("res://scene/caves.tscn")
		$AudioStreamPlayer.stop()
	elif button_type == "exit":
		get_tree().quit()
