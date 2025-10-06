extends CharacterBody2D

@onready var animacao: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $hitbox
@export var health: int = 3
@export var velocidade: float = 15.0

enum InimigoState {
	idle,
	walk,
	follow,
	attack,
	dead
}

const KNOCKBACK_DIRECTIONS = {
	"up": Vector2(0, -1),
	"down": Vector2(0, 1),
	"left": Vector2(-1, 0),
	"right": Vector2(1, 0)
}

var status: InimigoState
var is_following_player = false
var player: CharacterBody2D = null
var tempo_troca: float
var direction: Vector2 = Vector2.ZERO
var knockback_vector: Vector2 = Vector2.ZERO
var knockback_strength = 180
var dashCounter = 0
var dashLimit = 1

func _ready() -> void:
	go_to_walk_state()

func _physics_process(delta: float) -> void:
	move_and_slide()
	knockback_vector = knockback_vector.move_toward(Vector2.ZERO, 500 * delta)
	match status:
		InimigoState.walk:
			walk_state(delta)
		InimigoState.follow:
			follow_state(delta)
		InimigoState.attack:
			attack_state(delta)
		InimigoState.dead:
			dead_state(delta)

func go_to_walk_state():
	status = InimigoState.walk
	animacao.play("idle")

func go_to_follow_state():
	status = InimigoState.follow
	animacao.play("ataque2")

func go_to_attack_state():
	status = InimigoState.attack
	animacao.play("ataque2")

func go_to_dead_state():
	status = InimigoState.dead
	animacao.play("dead")
	velocity = Vector2.ZERO


func walk_state(delta):
	velocity = direction * velocidade + knockback_vector
	if is_following_player:
		go_to_follow_state()
		return
	tempo_troca -= delta
	if tempo_troca <= 0.0:
		mover_aleatorio()
		go_to_walk_state()
		return

func follow_state(_delta):
	if player == null or !is_following_player:
		go_to_walk_state()
		return
	var distancia = position.distance_to(player.position)
	direction = (player.position - position).normalized()
	if direction.x < 0:
		animacao.flip_h = true
	else:
		animacao.flip_h = false
	velocity = direction * velocidade * 3 + knockback_vector
	velocity.y = direction.y * velocidade * 2 + knockback_vector.y

	if distancia < 20:
		go_to_attack_state()
		return

	if health <= 0:
		go_to_dead_state()
		return

func attack_state(_delta):
	if player == null:
		go_to_walk_state()
		return

	if animacao.animation != "ataque2":
		animacao.play("ataque2")
	
	var distancia = position.distance_to(player.position)
	if distancia > 25:
		go_to_follow_state()
		return

	if health <= 0:
		go_to_dead_state()
		return

func dead_state(_delta):
	velocity = Vector2.ZERO
	if animacao.animation != "dead":
		animacao.play("dead")

func mover_aleatorio() -> void:
	var opcoes = [
		Vector2(1,0),
		Vector2(-1,0),
		Vector2(0,0)
	]
	direction = opcoes[randi() % opcoes.size()].normalized()
	if direction.x < 0:
		animacao.flip_h = true
		
	elif direction.x > 0:
		animacao.flip_h = false
	tempo_troca = randf_range(2.0, 5.0)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		is_following_player = true
		player = body
		go_to_follow_state()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == player:
		is_following_player = false
		player = null
		go_to_walk_state()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.levar_dano()
		go_to_attack_state()
		print("Inimigo atingiu o jogador")

func knockback(comando: StringName):
	if comando in KNOCKBACK_DIRECTIONS:
		knockback_vector = KNOCKBACK_DIRECTIONS[comando] * knockback_strength
		print("Knockback:", comando)

func levar_dano(dano: int):
	health -= dano
	if health <= 0:
		go_to_dead_state()
