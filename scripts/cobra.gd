extends CharacterBody2D

@onready var animacao: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $hitbox
@export var health: int = 3
@export var velocidade: float = 60.0
@export var dead = false
@export var jump_height = -50
@onready var explosion: Node2D = $Explosion
@onready var attack_area: Area2D = $attack_area
@onready var chao_detector: RayCast2D = $chao_detector
@onready var dash_duration: Timer = $dash_duration

enum CobraState {
	dead,
	walking,
	attack
}

const KNOCKBACK_DIRECTIONS = {
	"up": Vector2(0, -1),
	"down": Vector2(0, 1),
	"left": Vector2(-1, 0),
	"right": Vector2(1, 0)
}

var status: CobraState
var player: CharacterBody2D = null
var tempo_troca: float
var direction: Vector2 = Vector2.ZERO
var knockback_vector: Vector2 = Vector2.ZERO
var knockback_strength = 100
var attack_multiplier = 150.0

func _ready() -> void:
	go_to_walk_state()

func _physics_process(delta: float) -> void:
	if !chao_detector.is_colliding():
		direction = -direction
		animacao.flip_h = direction.x < 0
	if not is_on_floor():
		velocity = get_gravity()
	if animacao.flip_h:
		chao_detector.global_position = Vector2(global_position.x - 10, global_position.y)
		attack_area.global_position = Vector2(global_position.x - 30, global_position.y)
	else: 
		chao_detector.global_position = Vector2(global_position.x + 10, global_position.y)
		attack_area.global_position = Vector2(global_position.x + 30, global_position.y)
	move_and_slide()
	knockback_vector = knockback_vector.move_toward(Vector2.ZERO, 500 * delta)

	match status:
		CobraState.walking:
			walk_state(delta)
		CobraState.attack:
			attack_state(delta)
		CobraState.dead:
			dead_state(delta)

func go_to_walk_state():
	status = CobraState.walking
	animacao.play("walking")

func go_to_attack_state():
	status = CobraState.attack
	animacao.play("attacking")
	dash_duration.start()

func go_to_dead_state():
	velocity = Vector2.ZERO
	status = CobraState.dead
	animacao.play("dead")
	dead = true
	hitbox.process_mode = Node.PROCESS_MODE_DISABLED

func walk_state(delta):
	$attack_area/CollisionShape2D.set_deferred("monitoring", true)
	velocity = direction * velocidade + knockback_vector
	tempo_troca -= delta
	chao_detector.scale.y = 1.0
	if dead:
		go_to_dead_state()
		return
	if tempo_troca <= 0.0 && !dead:
		mover_aleatorio()
		go_to_walk_state()
		return

func attack_state(_delta):
	if dead:
		go_to_dead_state()
		return
	velocity = Vector2.ZERO
	await get_tree().create_timer(0.5).timeout
	velocity.x = direction.x * attack_multiplier


func dead_state(_delta):
	$attack_area/CollisionShape2D.set_deferred("monitoring", false)
	velocity = Vector2.ZERO
	await get_tree().create_timer(1).timeout
	modulate.a -= 0.025
	if modulate.a <= 0:
		queue_free()
		print("Cobra desapareceu")

func mover_aleatorio() -> void:
	var opcoes = [
		Vector2(1, 0),
		Vector2(-1, 0)
	]
	direction = opcoes[randi() % opcoes.size()].normalized()
	animacao.flip_h = direction.x < 0
	tempo_troca = randf_range(1.0, 5.0)

func knockback(comando: StringName):
	if comando in KNOCKBACK_DIRECTIONS:
		knockback_vector = KNOCKBACK_DIRECTIONS[comando] * knockback_strength
		print("Knockback:", comando)

func levar_dano(dano: int):
	health -= dano
	if health <= 0:
		dead = true
		return

func anim_tapa(directionExp: Vector2) -> void:
	explosion.get_children()[0].color = Color.html("#D10000")
	if health <= 0:
		directionExp = Vector2.ZERO

	if directionExp.x == -1:
		explosion.global_position = Vector2(global_position.x - 10, global_position.y)
	elif directionExp.x == 1:
		explosion.global_position = Vector2(global_position.x + 10, global_position.y)
	elif directionExp.y == 1:
		explosion.global_position = Vector2(global_position.x, global_position.y + 15)
	elif directionExp.y == -1:
		explosion.global_position = Vector2(global_position.x, global_position.y - 15)

	explosion.anim_tapa(directionExp)

func _on_attack_area_area_entered(area: Area2D) -> void:
	player = area.get_parent() 
	if player.is_in_group("Player") && !dead: 
		$attack_area/CollisionShape2D.set_deferred("monitoring", false)
		go_to_attack_state()
		return

func _on_hitbox_area_entered(area: Area2D) -> void:
	player = area.get_parent() 
	if player.is_in_group("Player") && !dead:
		player.levar_dano()
		return


func _on_dash_duration_timeout() -> void:
	go_to_walk_state()
	return
