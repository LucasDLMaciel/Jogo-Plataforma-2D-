extends CharacterBody2D
@onready var anim:AnimationPlayer = $cuckold_knight/AnimationPlayer
@onready var cuckold_knight: Sprite2D = $cuckold_knight
@onready var dash_duration: Timer = $timers/dash_duration
@onready var dash_effect: Timer = $timers/dash_Effect
@onready var dash_cooldown: Timer = $timers/dash_cooldown
@onready var area_2d: Area2D = $Area2D
@onready var area_2d_2: Area2D = $Area2D2
@onready var inimigo: CharacterBody2D = null
@onready var invecible_time: Timer = $timers/invecible_time
@onready var coyote_timer: Timer = $timers/coyote_timer
@onready var camera : Camera2D = null
@onready var hitbox: Area2D = $hitbox


enum PlayerState{
	idle,
	jump,
	falling,
	walking,
	dash,
	attack,
	dead
}


@export_category("Jump variable")
@export var jump_velocity = 300.0
@export var acceleration = 390.0
@export var jump_amount = 1
var jump_count = 0

@export_category("Speed variable")
@export var MAX_SPEED = 100.0
@export var acceleration_player = 400
@export var deceleration_player = 400

@export_category("Status player")
@export var Health = 3

var doDash = false
var dashDirection : int
var dashCounter = 0
var dashLimit = 1
var cooldown = false
var knockback_attack = 80.0
var pogo_modifier = 3
var is_invincible = false
var coyote_time_activated = false
var status: PlayerState
var knockback_strenght = -180.0

func _ready() -> void:
	go_to_idle_state()
	area_2d.monitoring = false
	area_2d_2.monitoring = false
	area_2d.monitorable = false
	area_2d_2.monitorable = false
	area_2d.modulate = Color.html("#FF0000")
	area_2d_2.modulate = Color.html("#FF0000")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		if !coyote_time_activated:
			coyote_timer.start()
			coyote_time_activated = true
	elif is_on_floor():
		if coyote_time_activated:
			coyote_timer.stop()
			coyote_time_activated = false
		if dashCounter == 1 && !cooldown:
			dashCounter = 0
			cooldown = false
	move_and_slide()
	match status:
		PlayerState.idle:
			idle_state(delta)
		PlayerState.walking:
			walking_state(delta)
		PlayerState.falling:
			falling_state(delta)
		PlayerState.jump:
			jump_state(delta)
		PlayerState.dash:
			dash_state(delta)
		PlayerState.attack:
			attack_state(delta)
		PlayerState.dead:
			dead_state(delta)

func go_to_dead_state():
	PlayerState.dead
	#anim.play("dead", 1.0, false)
	velocity = Vector2.ZERO
	await get_tree().create_timer(2).timeout
	get_tree().reload_current_scene()

func go_to_idle_state():
	status = PlayerState.idle
	anim.play("Idle")

func go_to_walking_state():
	status = PlayerState.walking
	anim.play("Walking")
	
func go_to_jump_state():
	status = PlayerState.jump
	anim.play("Idle")
	
func go_to_falling_state():
	status = PlayerState.falling
	anim.play("Falling")
	
func go_to_dash_state():
	status = PlayerState.dash
	anim.play("Idle")
	
func go_to_attack_state():
	status = PlayerState.attack
	#anim.play("attack")

func dead_state(_delta):
	pass
	
func idle_state(delta):
	andar(delta)
	jump_logic()
	dash()
	attack()
	if velocity.x != 0:
		go_to_walking_state()
		return
	if velocity.y < 0:
		go_to_jump_state()
		return
	if Input.is_action_pressed("attack"):
		go_to_attack_state()
		return
	if Input.is_action_just_pressed("dash"):
		go_to_dash_state()
		return

func walking_state(delta):
	andar(delta)
	jump_logic()
	dash()
	attack()
	if !is_on_floor():
		go_to_falling_state()
		return
	if velocity.x == 0:
		go_to_idle_state()
		return
	if velocity.y < 0:
		go_to_jump_state()
		return
	if Input.is_action_pressed("attack"):
		go_to_attack_state()
		return
	if Input.is_action_just_pressed("dash"):
		go_to_dash_state()
		return

func jump_state(delta):
	andar(delta)
	jump_logic()
	dash()
	attack()
	if Input.is_action_just_pressed("attack"):
		go_to_attack_state()
		return
	if Input.is_action_just_pressed("dash"):
		go_to_dash_state()
		return
	if velocity.y > 0:
		go_to_falling_state()
		return

func falling_state(delta):
	andar(delta)
	dash()
	jump_logic()
	attack()
	if Input.is_action_just_pressed("attack"):
		go_to_attack_state()
		return
	if velocity.y < 0:
		go_to_jump_state()
		return
	if is_on_floor():
		if velocity.x == 0:
			go_to_idle_state()
			return
		else:
			go_to_walking_state()
			return

func dash_state(delta):
	dash()
	jump_logic()
	andar(delta)
	if !is_on_floor():
			jump_count += 1
			go_to_falling_state()
			return
	if velocity.y < 0:
		go_to_jump_state()
		return
	if velocity.x == 0:
		go_to_idle_state()
		return
	else:
		go_to_walking_state()
		return

func attack_state(delta):
	attack()
	andar(delta)
	jump_logic()
	if anim.animation_finished: #&& anim.current_animation == "attack": #&& adicionar se a animação for attack
		area_2d.monitoring = false
		area_2d_2.monitoring = false
		area_2d_2.monitorable = false
		area_2d.monitorable = false
		area_2d.modulate = Color.html("#FF0000")
		area_2d_2.modulate = Color.html("#FF0000")
		if !is_on_floor():
			go_to_falling_state()
			return
		if velocity.x == 0:
			go_to_idle_state()
			return
		if velocity.y < 0:
			go_to_jump_state()
			return
		if velocity.x != 0:
			go_to_walking_state()
			return	
		if Input.is_action_just_pressed("dash"):
			go_to_dash_state()
			return
			
func efeito_dash(): 
	var playerCopyNode = cuckold_knight.duplicate()
	get_parent().add_child(playerCopyNode)
	playerCopyNode.global_position = global_position
	
	var AnimationTime = dash_duration.wait_time / 4
	var cor_ghost = Color.html("#4b92fe")
	playerCopyNode.modulate = cor_ghost
	await get_tree().create_timer(AnimationTime).timeout
	playerCopyNode.modulate.a = 0.4
	await get_tree().create_timer(AnimationTime).timeout
	playerCopyNode.modulate.a = 0.2
	await get_tree().create_timer(AnimationTime).timeout
	playerCopyNode.modulate.a = 0.1
	playerCopyNode.queue_free()

func _on_dash_timeout_timeout() -> void:
	doDash = false
	cooldown = true
	dash_effect.stop()

func _on_dash_effect_timeout() -> void:
	efeito_dash()

func _on_dash_cooldown_timeout() -> void:
	cooldown = false

func attack():
	if Input.is_action_just_pressed("attack"):
		if (Input.is_action_pressed("up") or Input.is_action_pressed("down")):
			area_2d_2.monitoring = true
			area_2d_2.monitorable = true
			area_2d_2.modulate = Color.html("#FF0000")
			#anim.play("attack")
			if Input.is_action_pressed("up"):
				area_2d_2.global_position = Vector2(global_position.x, global_position.y - 15.0)
			else:
				area_2d_2.global_position = Vector2(global_position.x, global_position.y + 15.0)
		else: 
			area_2d.monitoring = true
			area_2d.monitorable = true
			area_2d.modulate = Color.html("#FF0000")
			#anim.play("attack")
			if cuckold_knight.is_flipped_h():
				area_2d.global_position = Vector2(global_position.x - 12.0, global_position.y)
			else:
				area_2d.global_position = Vector2(global_position.x + 12.0, global_position.y)

func jump_logic():
	if is_on_floor():
		jump_count = 0
	if Input.is_action_just_pressed("jump") && (is_on_floor() || !coyote_timer.is_stopped()) && can_jump():
		velocity.y = 0
		print(jump_count)
		do_jump()
		print(jump_count)
		print("primeiro pulo ou coyote")
	elif Input.is_action_just_pressed("jump") && !is_on_floor() && can_jump():
		velocity.y = 0
		print(jump_count)
		do_jump()
		print(jump_count)
		print("doublejump")
	elif Input.is_action_just_released("jump") && jump_count <= jump_amount:
		velocity.y = lerp(velocity.y, get_gravity().y/1.4, 0.4)
		velocity.y *= 0.2
	else:
		return
func do_jump():
	jump_count += 1
	velocity.y -= lerp(jump_velocity, acceleration, 0.3)

func dash():
	if Input.is_action_just_pressed("dash") && dashCounter < dashLimit && !cooldown:
		var direction := Input.get_axis("left", "right")
		print("habilidade usada")
		dashCounter = 1
		@warning_ignore("narrowing_conversion")
		dashDirection = direction
		doDash = true
		cooldown = true
		dash_duration.start()
		dash_effect.start()
		dash_cooldown.start()
	
func levar_dano():
	var nodes = get_tree().get_nodes_in_group("Camera")
	if nodes.size() == 0:
		return
	camera = nodes[0]
	if is_invincible:
		return
	is_invincible = true
	#Health -= 1
	modulate = Color(1, 1, 1, 0.5)
	invecible_time.start()
	velocity.y += knockback_strenght
	camera.screen_shake(2, 0.3)
	frame_frezee(0.2, 0.2)
	print(Health)
	if Health == 0:
		if status != PlayerState.dead:
			go_to_dead_state()

func can_jump() -> bool:
	return jump_count < jump_amount
		
func andar(_delta):
	var direction := Input.get_axis("left", "right")
	if doDash:
		if dashDirection == 0:
			if cuckold_knight.is_flipped_h():
				dashDirection = -1
			else:
				dashDirection = 1
		velocity.x = dashDirection * MAX_SPEED * 3 
		velocity.y = 0
	else:	
		if direction:
				velocity.x = direction*MAX_SPEED
		else:
				velocity.x = move_toward(velocity.x, 0, MAX_SPEED)
	if direction < 0:
		cuckold_knight.flip_h = true
	elif direction > 0:
		cuckold_knight.flip_h = false
			
#função para freezar o tempo (tomar dano e etc)
func frame_frezee(timeScale, duration): 
	Engine.time_scale = timeScale
	await(get_tree().create_timer(duration * timeScale).timeout)
	Engine.time_scale = 1.0

func _on_invecible_time_timeout() -> void:
	is_invincible = false
	modulate = Color(1, 1, 1, 1)
	
func _on_coyote_timer_timeout() -> void:
	pass

func _on_hitbox_area_entered(area: Area2D) -> void:
	pass
func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.get_parent().is_in_group("inimigos"):
		area_2d_2.monitoring = false
		area_2d_2.modulate = Color.html("#FFFFFF")
		var last_direction = -1 if cuckold_knight.is_flipped_h() else 1
		inimigo = area.get_parent()
		inimigo.levar_dano(1)
		if !cuckold_knight.is_flipped_h():
			inimigo.knockback("right")
			velocity.x -= knockback_attack 
		else:
			inimigo.knockback("left")
			velocity.x += knockback_attack

func _on_area_2d_2_area_entered(area: Area2D) -> void:
	if area.get_parent().is_in_group("inimigos"):
		area_2d.monitoring = false
		area_2d.modulate = Color.html("#FFFFFF")
		inimigo = area.get_parent()
		inimigo.levar_dano(1)
		if not is_on_floor() && Input.is_action_pressed("down"):
			inimigo.knockback("down")
			velocity.y -= lerp(jump_velocity, acceleration*pogo_modifier, 0.1)
		elif Input.is_action_pressed("up"):
			inimigo.knockback("up")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim.animation == "attack":
		area_2d.monitoring = false
		area_2d_2.monitoring = false
		area_2d.modulate = Color.html("#FF0000")
		area_2d_2.modulate = Color.html("#FF0000")
		pass
