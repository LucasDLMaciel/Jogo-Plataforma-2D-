class_name Binds
extends Control

@onready var label: Label = $HBoxContainer/Label
@onready var label_2: Label = $HBoxContainer/Label2
@onready var sprite_2d: Sprite2D = $HBoxContainer/Sprite2D

@export var action_name : String = "left"

func _ready() -> void:
	set_action_name()
	set_text_for_key()

func set_action_name() -> void:
	label.text = "Unassigned"
	
	match action_name:
		"left":
			label.text = "Esquerda"
		"right":
			label.text = "Direita"
		"up":
			label.text = "Cima"
		"down":
			label.text = "Baixo"
		"jump":
			label.text = "Pular"
		"dash":
			label.text = "Rolar"
		"attack":
			label.text = "Ataque"
		"pause":
			label.text = "Pausar"

func set_text_for_key(): 
	var action_events = InputMap.action_get_events(action_name)
	var action_event = action_events[0] 
	var action_keycode = OS.get_keycode_string(action_event.physical_keycode) 
		
	label_2.text = "%s" % action_keycode
		
	match action_keycode:
		"A":
			sprite_2d.region_rect = Rect2(97.0, 338.0, 14.0, 10.0)
		"D":
			sprite_2d.region_rect = Rect2(113.0, 338.0, 14.0, 10.0)
		"W":
			sprite_2d.region_rect = Rect2(98.0, 321.0, 12.0, 14.0)
		"S":
			sprite_2d.region_rect = Rect2(115.0, 321.0, 12.0, 14.0)
		"Space":
			sprite_2d.region_rect = Rect2(16.0,48.0, 16.0, 16.0)
		"X":
			pass
		"Z":
			sprite_2d.region_rect = Rect2(334.0, 65.0, 19.0, 15.0)
		"Escape":
			sprite_2d.region_rect = Rect2(450.0, 115.0, 12.0, 11.0)
