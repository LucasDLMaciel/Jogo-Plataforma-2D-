extends CharacterBody2D

@onready var anim: AnimationPlayer = $Monge_boss/AnimationPlayer
@onready var Hitbox: Area2D = $Hitbox
@export var health: int = 40
@export var hit: int = 0
@onready var player_detector: RayCast2D = $PlayerDetector
@export var velocidade: float = 40.0
@export var dodge_velocidade: float = 200.0
@onready var sprite: Sprite2D = $Monge_boss
@onready var reto_hitbox: Area2D = $"Staff Hitbox"
@onready var cima_hitbox: Area2D = $"Cima hitbox"
@export var pode_atacar = true
@onready var roll_hitbox: Area2D = $"Roll Hitbox"
@export var fase = 1
@export var jump_velocity = 200
enum MongeState {
	idle,
	walk,
	attack,
	roll,
	dead
}	

const KNOCKBACK_DIRECTIONS = {
	"left": Vector2(-1, 0),
	"right": Vector2(1, 0)
}

var status: MongeState
var player: CharacterBody2D
var tempo_troca: float
var direction: Vector2 = Vector2.ZERO
var knockback_vector: Vector2 = Vector2.ZERO
var knockback_strength = 180
var current_attack: String = ""
var dead = false
var target
var is_attacking
var is_rolling
var doRoll
var camera
var rollDirection = 0
@onready var attack_timer: Timer = $attack_timer
@onready var projectile_scene

func _ready() -> void:
	var nodes = get_tree().get_nodes_in_group("Camera")
	if nodes.size() == 0:
		return
	camera = nodes[0]
	go_to_walk_state()

func _process(delta: float) -> void:
	if hit >= health*0.4:
		fase = 2
	var nodes = get_tree().get_nodes_in_group("Player")
	if nodes.size() == 0:
		push_error("Não achei o player")
		return 
	target = nodes[0]
	if !dead && !is_attacking && !is_rolling:
		player_detector.target_position = player_detector.to_local(target.position)
		_atualizar_direcao_por_raycast()

func _physics_process(delta: float) -> void:
	if not is_on_floor() && !is_attacking:
		velocity.y = jump_velocity*velocidade*delta
	move_and_slide()
	knockback_vector = knockback_vector.move_toward(Vector2.ZERO, 500 * delta)
	match status:
		MongeState.idle:
			idle_state(delta)
		MongeState.walk:
			walk_state(delta)
		MongeState.attack:
			attack_state(delta)
		MongeState.dead:
			dead_state(delta)
		
func go_to_walk_state():
	status = MongeState.walk
	anim.play("Walking", -1, 1.0)

func go_to_attack_state():
	status = MongeState.attack
	escolher_ataque()

func go_to_dead_state():
	status = MongeState.dead
	#anim.play("dead")
	velocity = Vector2.ZERO
	await(get_tree().create_timer(0.2).timeout)
	Hitbox.process_mode = Node.PROCESS_MODE_DISABLED

func go_to_idle_state():
	status = MongeState.idle
	anim.play("Idle", -1, 2.0)
	velocity = Vector2.ZERO

func idle_state(delta):
	if player_detector.is_colliding() && pode_atacar && !dead && !is_rolling && is_on_floor():
		go_to_attack_state()
		return

func walk_state(delta):
	if doRoll:
		if direction.x < 0:
			rollDirection = -1
		if direction.x > 0:
			rollDirection = +1
		velocity.x = rollDirection * dodge_velocidade + knockback_vector.x
		velocity.y = 0
	else:
		velocity = direction * velocidade + knockback_vector
	if player_detector.is_colliding() && pode_atacar && !dead && !is_rolling && is_on_floor():
		go_to_attack_state()
		return
	

func attack_state(_delta):
	velocity = Vector2.ZERO
	velocity = direction * knockback_vector 
	if health <= 0:
		go_to_dead_state()
		return
	if doRoll:
		go_to_walk_state()
		return
		

func dead_state(_delta):
	dead = true
	pass
	#if anim.animation != "dead":
		#anim.play("dead")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if Hitbox.process_mode == PROCESS_MODE_DISABLED:
		return
	if body.is_in_group("Player"):
		player = body

func _on_area_2d_body_exited(body: Node2D) -> void:
	if Hitbox.process_mode == PROCESS_MODE_DISABLED:
			return
	go_to_walk_state()	

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.levar_dano()

func knockback(comando: StringName):
	if comando in KNOCKBACK_DIRECTIONS:
		knockback_vector = KNOCKBACK_DIRECTIONS[comando] * knockback_strength
		print("Knockback:", comando)

func min_hitbox() -> void:
	Hitbox.scale.y = 0.5
	Hitbox.global_position.y = global_position.y + 20
	
func max_hitbox() -> void:
	Hitbox.scale.y = 1
	Hitbox.global_position.y = global_position.y

func levar_dano(dano: int):
	health -= dano
	print(health)
	hit += dano
	print(hit)
	if health <= 0:
		go_to_dead_state()

func escolher_ataque():
	pode_atacar = false 
	if fase == 1:
		current_attack = ["reto", "cima", "projetil"].pick_random()
	else:
		current_attack = ["reto", "cima", "projetil", "combo_projetil"].pick_random()
	atacar(current_attack)

func atacar(tipo : String):
	is_attacking = true
	match tipo:
		"reto":
			camera.screen_shake(6, 1)
			camera.frame_frezee(0.2, 0.2)
			if sprite.flip_h == false:
				reto_hitbox.global_position.x = global_position.x+154
			else:
				reto_hitbox.global_position.x = global_position.x-154
			anim.play("StaffAttack", -1, 1.0*fase)
			await get_tree().create_timer(1).timeout
			reto_hitbox.get_node("CollisionShape2D").set_deferred("disabled", false)
			await anim.animation_finished
			reto_hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)
			print("ataque reto")
		"cima":
			#anim.play("cima")
			jump()
			anim.play("StaffAttack", -1, 1.0*fase)
			camera.screen_shake(6, 4)
			camera.frame_frezee(0.2, 0.2)
			if sprite.flip_h == false:
				cima_hitbox.global_position.x = global_position.x+100
			else:
				cima_hitbox.global_position.x = global_position.x-100
			await get_tree().create_timer(1).timeout
			cima_hitbox.get_node("CollisionShape2D").set_deferred("disabled", false)
			await anim.animation_finished
			cima_hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)
			print("ataque para cima")
		
		#"projetil":
			#anim.play("projetil")
			#await get_tree().create_timer(0.4).timeout
			#atirar_projetil()
			#await anim.animation_finished
			#print("ataque projetil único")
#
		#"combo_projetil":
			#anim.play("projetil")
			#for i in range(3):
				#await get_tree().create_timer(0.3).timeout
				#atirar_projetil()
			#await anim.animation_finished
			#print("combo de projeteis (fase 2)")

	attack_timer.start(1.0/fase)	
	is_attacking = false
	go_to_walk_state()
	return
	

func jump():
	velocity.y += -jump_velocity*velocidade

func atirar_projetil():
	var proj = projectile_scene.instantiate()
	add_sibling(proj)
	proj.global_position = Vector2(self.position.x, self.position.y - 40)
	proj.direction = sign(player.global_position.x - global_position.x)

func _on_attack_timer_timeout() -> void:
	pode_atacar = true
	
func _atualizar_direcao_por_raycast():
	if !is_attacking && !is_rolling:
		if player_detector.target_position.x > 0:
			direction.x = 1
			sprite.flip_h = false
		elif player_detector.target_position.x < 0:
			direction.x = -1
			sprite.flip_h = true

func _on_staff_hitbox_area_entered(area: Area2D) -> void:
	var player
	if area.get_collision_layer_value(2):
		player = area.get_parent()
		player.levar_dano()

func _on_roll_hitbox_area_entered(area: Area2D) -> void:
	player = area.get_parent()
	if player.is_in_group("Player") && !is_attacking:
		doRoll = true
		is_rolling = true
		min_hitbox()
		go_to_walk_state()
		return

func _on_roll_hitbox_area_exited(area: Area2D) -> void:
	await get_tree().create_timer(0.5).timeout
	doRoll = false
	is_rolling = false
	max_hitbox()

func _on_hitbox_area_entered(area: Area2D) -> void:
		player = area.get_parent()
		if player.is_in_group("Player"):
			player.levar_dano()
			print("Inimigo atingiu o jogador")
