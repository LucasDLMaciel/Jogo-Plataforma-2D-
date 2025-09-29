extends CharacterBody2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var dash_duration: Timer = $dash_duration
@onready var dash_effect: Timer = $dash_Effect
@onready var dash_cooldown: Timer = $dash_cooldown
@onready var area_2d: Area2D = $Area2D
@onready var area_2d_2: Area2D = $Area2D2
@onready var inimigo: CharacterBody2D = null
@onready var invecible_time: Timer = $invecible_time
@onready var coyote_timer: Timer = $coyote_timer

enum PlayerState{
	idle,
	jump,
	fall,
	walk,
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
@export var MAX_SPEED = 80.0
@export var acceleration_player = 40
@export var deceleration_player = 400

var doDash = false
var dashDirection : int
var dashCounter = 0
var dashLimit = 1
var cooldown = false
var knockback_attack = 15.0
var pogo_modifier = 3
var knockback_vector: Vector2 = Vector2.ZERO
var knockback_strength = 80.0
var is_invincible = false
var coyote_time_activated = false
var status: PlayerState

func _ready() -> void:
	go_to_idle_state()
	area_2d.monitoring = false
	area_2d_2.monitoring = false

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
		
	if knockback_vector != Vector2.ZERO:
		velocity += knockback_vector
		knockback_vector = knockback_vector.move_toward(Vector2.ZERO, 400 * delta) # suaviza o knockback
	move_and_slide()
	match status:
		PlayerState.idle:
			idle_state(delta)
		PlayerState.walk:
			walk_state(delta)
		PlayerState.fall:
			fall_state(delta)
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
	anim.play("dead")
	velocity = Vector2.ZERO

func go_to_idle_state():
	status = PlayerState.idle
	anim.play("idle")

func go_to_walk_state():
	status = PlayerState.walk
	anim.play("walk")
	
func go_to_jump_state():
	status = PlayerState.jump
	anim.play("jump")
	
func go_to_fall_state():
	status = PlayerState.fall
	anim.play("fall")
	
func go_to_dash_state():
	status = PlayerState.dash
	anim.play("idle")
	
func go_to_attack_state():
	status = PlayerState.attack
	anim.play("attack")

func dead_state(_delta):
	pass
	
func idle_state(delta):
	andar(delta)
	jump_logic()
	dash()
	attack()
	if velocity.x != 0:
		go_to_walk_state()
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

func walk_state(delta):
	andar(delta)
	jump_logic()
	dash()
	attack()
	if !is_on_floor():
		go_to_fall_state()
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
		go_to_fall_state()
		return

func fall_state(delta):
	andar(delta)
	dash()
	jump_logic()
	if velocity.y < 0:
		go_to_jump_state()
		return
	if is_on_floor():
		if velocity.x == 0:
			go_to_idle_state()
			return
		else:
			go_to_walk_state()
			return

func dash_state(delta):
	dash()
	jump_logic()
	andar(delta)
	if !is_on_floor():
			jump_count += 1
			go_to_fall_state()
			return
	if velocity.y < 0:
		go_to_jump_state()
		return
	if velocity.x == 0:
		go_to_idle_state()
		return
	else:
		go_to_walk_state()
		return

func attack_state(delta):
	attack()
	andar(delta)
	jump_logic()
	if !anim.is_playing():
		if !is_on_floor():
			go_to_fall_state()
			return
		if velocity.x == 0:
			go_to_idle_state()
			return
		if velocity.y < 0:
			go_to_jump_state()
			return
		if velocity.x != 0:
			go_to_walk_state()
			return	
		if Input.is_action_just_pressed("dash"):
			go_to_dash_state()
			return
			
func efeito_dash(): 
	var playerCopyNode = $AnimatedSprite2D.duplicate()
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
			anim.play("attack")
			if Input.is_action_pressed("up"):
				area_2d_2.global_position = Vector2(global_position.x, global_position.y - 15.0)
			else:
				area_2d_2.global_position = Vector2(global_position.x, global_position.y + 15.0)
		else: 
			area_2d.monitoring = true
			anim.play("attack")
			if anim.is_flipped_h():
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
		area_2d.monitoring = false
		area_2d_2.monitoring = false
		print("habilidade usada")
		dashCounter = 1
		@warning_ignore("narrowing_conversion")
		dashDirection = direction
		doDash = true
		cooldown = true
		dash_duration.start()
		dash_effect.start()
		dash_cooldown.start()
	
func levar_knockback(from_position: Vector2):
	if is_invincible:
		return
	
	var knockback_dir = (position - from_position).normalized()
	knockback_vector = knockback_dir * knockback_strength
	
	is_invincible = true
	modulate = Color(1, 1, 1, 0.5)
	invecible_time.start()
	print("colisao - knockback jogador")

func can_jump() -> bool:
	return jump_count < jump_amount
		
func andar(delta):
	var direction := Input.get_axis("left", "right")
	if doDash:
		if dashDirection == 0:
			if anim.is_flipped_h():
				dashDirection = -1
			else:
				dashDirection = 1
		velocity.x = dashDirection * MAX_SPEED * 3 
		velocity.y = 0
	else:	
		if direction:
			if cooldown:
				velocity.x = move_toward(velocity.x, 0, MAX_SPEED)
			else:
				velocity.x = move_toward(velocity.x, direction*MAX_SPEED, acceleration * delta)
		else:
			if cooldown:
				velocity.x = move_toward(velocity.x, 0, MAX_SPEED)
			else:
				velocity.x = move_toward(velocity.x, 0, deceleration_player * delta)
	if direction < 0:
		anim.flip_h = true
	elif direction > 0:
		anim.flip_h = false
			
#função para freezar o tempo (tomar dano e etc)
func frame_frezee(timeScale, duration): 
	Engine.time_scale = timeScale
	await(get_tree().create_timer(duration * timeScale).timeout)
	Engine.time_scale = 1.0

func _on_invecible_time_timeout() -> void:
	is_invincible = false
	modulate = Color(1, 1, 1, 1)
	
func _on_coyote_timer_timeout() -> void:
	pass # Replace with function body.

func _on_hitbox_area_entered(area: Area2D) -> void:
	go_to_dead_state()
	return
func _on_area_2d_area_entered(area: Area2D) -> void:
	area_2d_2.monitoring = false
	var last_direction = -1 if anim.is_flipped_h() else 1
	area.get_parent().health -= 1
	if !anim.is_flipped_h():
		area.get_parent().knockback("right")
		velocity.x += (-last_direction) * knockback_attack
	else:
		area.get_parent().knockback("left")
		velocity.x += (-last_direction) * knockback_attack
	if area.get_parent().health == 0:
		area.get_parent().queue_free()


func _on_area_2d_2_area_entered(area: Area2D) -> void:
	area_2d.monitoring = false
	area.get_parent().health -= 1
	if not is_on_floor() && Input.is_action_pressed("down"):
		area.get_parent().knockback("down")
		velocity.y -= lerp(jump_velocity, acceleration*pogo_modifier, 0.1)
	elif Input.is_action_pressed("up"):
		area.get_parent().knockback("up")
	if area.get_parent().health == 0:
		area.get_parent().queue_free()
