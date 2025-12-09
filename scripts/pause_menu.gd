extends Control

var visivel

func _ready() -> void:
	hide()
	
func _process(delta: float) -> void:
	testpause()
	
func testpause()->void:
	if Input.is_action_just_pressed("pause") && !visivel:
		visivel = true
		$PanelContainer/VBoxContainer/Start.grab_focus()
		$AnimationPlayer.play("blur")
		show()
		if $Controles.visible == true:
			$PanelContainer.show()
			$Controles.hide()
			$PanelContainer/VBoxContainer/Resume.grab_focus()
	elif Input.is_action_just_pressed("pause") && visivel:
		visivel = false
		$AnimationPlayer.play_backwards("blur")
		hide()

func _on_start_pressed() -> void:
	$Menu_click.play()
	visivel = false
	hide()

func _on_exit_pressed() -> void:
	$Menu_click.play()
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")

func _on_controls_pressed() -> void:
	$Controles.show()
	$Controles/MarginContainer/ScrollContainer/VBoxContainer/Sair.grab_focus()
	$Menu_click.play()
	$PanelContainer.hide()

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

func _on_sair_pressed() -> void:
	$PanelContainer.show()
	$Controles.hide()
	$PanelContainer/VBoxContainer/Controls.grab_focus()
	$Menu_click.play()
