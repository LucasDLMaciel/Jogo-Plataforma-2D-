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
	walk,
	dash,
	attack
}

@export_category("Jump variable")
@export var jump_velocity = 300.0
@export var acceleration = 390.0
@export var jump_amount = 1
var jump_count = 0

var SPEED = 80.0
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
			idle_state()
		PlayerState.walk:
			walk_state()
		PlayerState.jump:
			jump_state()
		PlayerState.dash:
			dash_state()
		PlayerState.attack:
			attack_state()

func go_to_idle_state():
	status = PlayerState.idle
	anim.play("idle")

func go_to_walk_state():
	status = PlayerState.walk
	anim.play("walk")
	
func go_to_jump_state():
	status = PlayerState.jump
	anim.play("jump")
	
func go_to_dash_state():
	status = PlayerState.dash
	anim.play("idle")
	
func go_to_attack_state():
	status = PlayerState.attack
	anim.play("attack")

func idle_state():
	andar()
	jump_logic()
	dash()
	attack()
	if velocity.x != 0:
		go_to_walk_state()
		return
	if velocity.y != 0:
		go_to_jump_state()
		return
	if Input.is_action_pressed("attack"):
		go_to_attack_state()
		return
	if Input.is_action_just_pressed("dash"):
		go_to_dash_state()
		return
	
func walk_state():
	andar()
	jump_logic()
	dash()
	attack()
	if velocity.x == 0:
		go_to_idle_state()
		return
	if velocity.y != 0:
		go_to_jump_state()
		return
	if Input.is_action_pressed("attack"):
		go_to_attack_state()
		return
	if Input.is_action_just_pressed("dash"):
		go_to_dash_state()
		return

func jump_state():
	andar()
	jump_logic()
	dash()
	attack()
	if Input.is_action_just_pressed("attack"):
		go_to_attack_state()
		return
	if is_on_floor():
		if velocity.x == 0:
			go_to_idle_state()
			return
		else:
			go_to_walk_state()
			return
	if Input.is_action_just_pressed("dash"):
		go_to_dash_state()
		return

func dash_state():
	dash()
	jump_logic()
	andar()
	if velocity.y != 0:
		go_to_jump_state()
		return
	if velocity.x == 0:
		go_to_idle_state()
		return
	else:
		go_to_walk_state()
		return

func attack_state():
	attack()
	andar()
	jump_logic()
	if !anim.is_playing():
		if velocity.x == 0:
			go_to_idle_state()
			return
		if velocity.y != 0:
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
	if Input.is_action_just_pressed("jump") && (is_on_floor() || !coyote_timer.is_stopped()) && jump_count < jump_amount:
		velocity.y = 0
		print(jump_count)
		do_jump()
		print(jump_count)
		print("primeiro pulo ou coyote")
	elif Input.is_action_just_pressed("jump") && !is_on_floor() && jump_count < jump_amount:
		velocity.y = 0
		print(jump_count)
		do_jump()
		print(jump_count)
		print("doublejump")
	elif Input.is_action_just_released("jump") && jump_count <= jump_amount:
		velocity.y = lerp(velocity.y, get_gravity().y, 0.4)
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

		
func andar():
	var direction := Input.get_axis("left", "right")
	if doDash:
		if dashDirection == 0:
			if anim.is_flipped_h():
				dashDirection = -1
			else:
				dashDirection = 1
		velocity.x = dashDirection * SPEED * 3
		velocity.y = 0
	else:	
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	if direction < 0:
		anim.flip_h = true
	elif direction > 0:
		anim.flip_h = false
			
#			função para freezar o tempo (tomar dano e etc)
func frame_frezee(timeScale, duration): 
	Engine.time_scale = timeScale
	await(get_tree().create_timer(duration * timeScale).timeout)
	Engine.time_scale = 1.0
	

func _on_area_2d_body_entered(body: Node2D) -> void:
	area_2d_2.monitoring = false
	var last_direction = -1 if anim.is_flipped_h() else 1
	if body.is_in_group("inimigos"):
		body.health -= 1
		if !anim.is_flipped_h():
			body.knockback("right")
			velocity.x += (-last_direction) * knockback_attack
		else:
			body.knockback("left")
			velocity.x += (-last_direction) * knockback_attack
		if body.health == 0:
			body.queue_free()


func _on_area_2d_2_body_entered(body: Node2D) -> void:
	area_2d.monitoring = false
	if body.is_in_group("inimigos"):
		body.health -= 1
		if not is_on_floor() && Input.is_action_pressed("down"):
			body.knockback("down")
			velocity.y -= lerp(jump_velocity, acceleration*pogo_modifier, 0.1)
		elif Input.is_action_pressed("up"):
			body.knockback("up")
		if body.health == 0:
			body.queue_free()

func _on_invecible_time_timeout() -> void:
	is_invincible = false
	modulate = Color(1, 1, 1, 1)
	
	#ex physics_process
	#func temp(delta: float) -> void:
	#jump_logic()
	#jump_amount = 1
	#if	Input.is_action_just_pressed("dash") && dashCounter < dashLimit && !cooldown && anim.animation != "attack" && anim.animation == "idle":
		#anim.play("get up", 2, false)
		#area_2d.monitoring = false
		#area_2d_2.monitoring = false
		#dash(direction)
	#else: 
		#andar(direction)
	#attack()
	#if is_on_floor():
		#if coyote_time_activated:
			#coyote_timer.stop()
			#coyote_time_activated = false
		#if dashCounter == 1 && !cooldown:
			#dashCounter = 0
			#cooldown = false
		#if direction > 0:
			##anim.play("walk")
			#anim.set_flip_h(false)
		#else: 
			#if direction < 0: 
				##anim.play("walk")
				#anim.set_flip_h(true)
	#if not is_on_floor():
		#if !coyote_time_activated:
			#coyote_timer.start()
			#coyote_time_activated = true
		#if direction > 0:
				##anim.play("walk")
			#anim.set_flip_h(false)
		#else: 
			#if direction < 0: 
					##anim.play("walk")
				#anim.set_flip_h(true)


func _on_coyote_timer_timeout() -> void:
	pass # Replace with function body.
