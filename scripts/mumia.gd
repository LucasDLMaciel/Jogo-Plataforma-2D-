extends CharacterBody2D

const VELOCIDADE = 30.0
@onready var animacao: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_patrolling: Area2D = $"Area patrolling"
@onready var area_2d: Area2D = $Area2D
@export var health: int 

var player: CharacterBody2D = null
var is_following_player: bool = false
var direcao: Vector2 = Vector2.ZERO
var tempo_troca: float = 0.0


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		move_and_slide()
	
	if is_following_player:
		var dir = (player.position - position).normalized()
		animacao.flip_h = dir.x < 0
		velocity = dir * VELOCIDADE * 2
		move_and_slide()
	else:
		# Movimento aleatório
		if is_on_floor():
			tempo_troca -= delta
			if tempo_troca <= 0.0:
				_mover_aleatorio()
			velocity = direcao * VELOCIDADE
			if velocity.length() > 0:
				if animacao.animation != "andando":
					animacao.play("andando")
			else:
				if animacao.animation != "andando":
					animacao.play("andando")
			move_and_slide()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.is_in_group("Player"):
		player = body
		is_following_player = true


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == player:
		is_following_player = false
		body = null
		if animacao.animation != "andando":
			animacao.play("andando")


func _mover_aleatorio() -> void:
	var opcoes = [
		Vector2(1, 0),
		Vector2(-1, 0)
	]
	direcao = opcoes[randi() % opcoes.size()].normalized()
	if direcao[0] < 0 :
			animacao.set_flip_h(true)
	elif direcao[0] > 0:
			animacao.set_flip_h(false)
	tempo_troca = randf_range(2.0, 4.0) # troca direção entre 2 e 4 segundos


func _on_areaattack_2d_body_exited(_body: Node2D) -> void:
		if animacao.animation != "andando":
			animacao.play("andando")


func _on_areaattack_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player = body
		if animacao.animation != "ataque":
			animacao.play("ataque")
			print("toma dano")

func knockback(comando: StringName):
	match comando :
		"down":
			position.y -= lerp(velocity.y, -20.0, 0.3)
		"up":
			position.y -= lerp(velocity.y, +20.0, 0.3)
		"left":
			position.x += lerp(velocity.x, -20.0, 0.3)
		"right":
			position.x -= lerp(velocity.x, +20.0, 0.3)
