extends CharacterBody2D

const velocidade = 15.0
@onready var animacao: AnimatedSprite2D = $AnimatedSprite2D
@export var health : int = 3
@onready var hitbox: Area2D = $hitbox

var is_following_player = false
var player : CharacterBody2D = null
var tempo_troca : float
var direction: Vector2 = Vector2.ZERO
var dashCounter = 0
var dashLimit = 1
var knockback_vector: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if is_following_player:
		if animacao.animation != "ataque2":
			animacao.play("ataque2")
		direction = (player.position - position).normalized()
		if direction[0] < 0 :
			animacao.set_flip_h(true)
		else:
			animacao.set_flip_h(false)
		velocity = direction * velocidade * 3 + knockback_vector
		velocity.y = direction[1] * velocidade * 2 + knockback_vector[1]
		move_and_slide()
	else: 
		tempo_troca -= delta
		if tempo_troca <= 0.0:
			animacao.play("idle")
			mover_aleatorio()
		velocity = direction * velocidade + knockback_vector
		move_and_slide()
	knockback_vector = knockback_vector.move_toward(Vector2.ZERO, 500 * delta)
	

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.is_in_group("Player"):
		is_following_player = true
		player = body


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == player:
		is_following_player = false
		body = null
		if animacao.animation != "idle":
			animacao.play("idle")
	
func mover_aleatorio() -> void :
	var aleatorio = randi_range(0,1)
	var opcoes = [
		Vector2(1,0),
		Vector2(-1,0),
		Vector2(0,0),
	]
	direction = opcoes[randi()%opcoes.size()].normalized()
	if direction[0] < 0 :
			animacao.set_flip_h(true)
	elif direction[0] > 0:
			animacao.set_flip_h(false)
	tempo_troca = randf_range(2.0, 5.0)
	


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body = player
		if direction[0] < 0:
			body.velocity.x += lerp(velocity.x, -20.0, 0.3)
		elif direction[0] > 0:
			body.velocity.x -= lerp(velocity.x, +20.0, 0.3)
		print("bosta")
		
func knockback(comando: StringName):
	match comando :
		"down":
			knockback_vector = Vector2(0, 150)
		"up":
			knockback_vector = Vector2(0, -150)
		"left":
			knockback_vector = Vector2(-150, 0)
		"right":
			knockback_vector = Vector2(150, 0)
