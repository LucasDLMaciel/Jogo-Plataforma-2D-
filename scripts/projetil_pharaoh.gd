extends Area2D

@export var speed: float = 220.0
var direction: Vector2 = Vector2.ZERO
var colidiu = false

@onready var anim: AnimatedSprite2D = $"projetil-pharoh"
@onready var timer: Timer = $timer

func _ready():
	timer.start()
	anim.play("Rodando")

func _process(delta):
	if colidiu:
		return
	
	position += direction * speed * delta

func set_direction(dir: Vector2):
	direction = dir.normalized()

func _on_area_entered(area: Area2D):
	if colidiu:
		return
	colidiu = true
	var player
	if area.get_collision_layer_value(2):
		player = area.get_parent()
		player.levar_dano(1)
	await get_tree().create_timer(0.25).timeout
	queue_free()
func _on_timer_timeout():
	queue_free()

func tocar_sfx():
	$sfx.play()
