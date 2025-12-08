extends ScrollContainer

@export var text_node : RichTextLabel
@export_range(1, 100000,0.1) var credits_time : float = 1
@export_range(1, 100000,0.1) var margin_increment : float = 0

@onready var margin : MarginContainer = $MarginContainer

func _ready() -> void:
	await get_tree().process_frame       # Espera UI carregar
	await get_tree().process_frame       # Garante que o texto calculou altura

	var tween = create_tween()

	BackgroundMusic.stop()
	$AudioStreamPlayer.play()

	var text_box_size = text_node.get_content_height()
	var window_size = DisplayServer.window_get_size().y

	margin.add_theme_constant_override("margin_top", window_size)

	var scroll_amount = text_box_size + window_size + margin_increment
	
	tween.tween_property(self, "scroll_vertical", scroll_amount, credits_time)
	tween.finished.connect(menu_principal)

	
func menu_principal():
	$MarginContainer/Control/Button.show()

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
	$AudioStreamPlayer.stop()
