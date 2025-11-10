extends CharacterBody2D

enum CactoEstado { IDLE, attack, dead}
var status: CactoEstado
@onready var hitbox: Area2D = $hitbox
@onready var anim: AnimationPlayer = $animacao_cacto/AnimationPlayer
@onready var sprite: Sprite2D = $animacao_cacto
@onready var PlayerDetector: RayCast2D = $PlayerDetector
@onready var duracao_anim: Timer = $duracao_anim
@onready var attack_cooldown: Timer = $attack_cooldown

@export_category("Enemy Health")
@export var Health = 3


const KNOCKBACK_DIRECTIONS = {
	"up": Vector2(0, -1),
	"down": Vector2(0, 1),
	"left": Vector2(-1, 0),
	"right": Vector2(1, 0)
}
var knockback_strength = 180
var knockback_vector: Vector2 = Vector2.ZERO
const ESPINHO = preload("res://entitys/espinho.tscn")
var direction = 1
var can_attack = false
var can_throw = true
var dead = false
var target
var nodes

func _ready() -> void:
	go_to_idle_state()

func _process(delta: float) -> void:
	if Health <= 0:
		hitbox.get_node("CollisionShape2D").set_deferred("disabled", false)
	nodes = get_tree().get_nodes_in_group("Player")
	if nodes.size() == 0:
		push_error("Não achei o player")
		return 
	target = nodes[0]
	if can_attack && !dead:
		PlayerDetector.target_position = PlayerDetector.to_local(target.position)
		_atualizar_direcao_por_raycast()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	knockback_vector = knockback_vector.move_toward(Vector2.ZERO, 500 * delta)
	match status:
		CactoEstado.IDLE:
			idle_state()
		CactoEstado.attack:
			attack_state()
		CactoEstado.dead:
			dead_state()
	move_and_slide()

func go_to_idle_state():
	status = CactoEstado.IDLE
	anim.play("idle")

func go_to_dead_state():
	status = CactoEstado.dead
	anim.play("dead")
	dead = true
	await get_tree().create_timer(1.5).timeout
	set_collision_mask_value(2, false)
	explode()
	await get_tree().create_timer(0.25).timeout
	queue_free()

func go_to_attack_state():
	status = CactoEstado.attack
	anim.play("attack")
	duracao_anim.start()
	if attack_cooldown.is_stopped():
		can_throw = true
	
	
func idle_state():
	if PlayerDetector.is_colliding() && can_attack && can_throw && !dead:
		go_to_attack_state()
		return

func attack_state():
	if can_throw && duracao_anim.is_stopped() && !dead:
		throw_spike()
		can_throw = false
		attack_cooldown.start()
		
func dead_state():
	pass

func throw_spike():
	var new_spike = ESPINHO.instantiate()
	add_sibling(new_spike)
	new_spike.position = Vector2(self.position.x, self.position.y - 5)
	var dir = (PlayerDetector.target_position - PlayerDetector.position).normalized()
	new_spike.set_direction(-dir)
	new_spike.timer.start()
	
func _atualizar_direcao_por_raycast():
	if PlayerDetector.target_position.x > 0:
		direction = 1
		sprite.flip_h = false
	else:
		direction = -1
		sprite.flip_h = true

func explode() -> void:
	var direcoes = [
	Vector2(1, 0),
	Vector2(-1, 0),
	Vector2(0, 1),
	Vector2(0, -1),
	Vector2(1, 1).normalized(),
	Vector2(1, -1).normalized(),
	Vector2(-1, 1).normalized(),
	Vector2(-1, -1).normalized() 
	]

	for dir in direcoes:
		var spike = ESPINHO.instantiate()
		add_sibling(spike)
		spike.global_position = global_position
		spike.set_direction(dir)
	
func _on_area_2d_area_entered(_area: Area2D) -> void:
	can_attack = true

func _on_area_2d_area_exited(_area: Area2D) -> void:
	can_attack = false

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	if anim.animation_finished:
		go_to_idle_state()
		return

func levar_dano(dano: int):
	Health -= dano
	print("cacto levou dano")
	if Health <= 0:
		go_to_dead_state()
		print("cacto morreu")

func knockback(comando: StringName):
	if comando in KNOCKBACK_DIRECTIONS:
		knockback_vector = KNOCKBACK_DIRECTIONS[comando] * knockback_strength
		print("Knockback:", comando)


func _on_attack_cooldown_timeout() -> void:
	can_throw = true
