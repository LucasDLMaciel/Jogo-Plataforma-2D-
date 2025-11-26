extends Area2D

var speed = 90
var direction = 1
var colidiu = false
@onready var timer: Timer = $timer

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if colidiu:
		position = position
		return
	position += speed * delta * direction
	
func set_direction(direction: Vector2):
	self.direction = direction.normalized()

func _on_area_entered(area: Area2D) -> void:
	colidiu = true
	var player
	if area.get_collision_layer_value(2):
		player = area.get_parent()
		player.levar_dano()
	queue_free()

func _on_timer_timeout() -> void:
	queue_free()
