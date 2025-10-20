extends CharacterBody2D
@onready var anim_player:AnimationPlayer = $cuckold_knight/AnimationPlayer
@onready var cuckold_knight: Sprite2D = $cuckold_knight
@onready var blade_sprite: Sprite2D = $blade_sprite
@onready var anim_blade: AnimationPlayer = $blade_sprite/AnimationPlayer
@onready var dash_duration: Timer = $timers/dash_duration
@onready var dash_effect: Timer = $timers/dash_Effect
@onready var dash_cooldown: Timer = $timers/dash_cooldown
@onready var area_2d: Area2D = $Area2D
@onready var area_2d_2: Area2D = $Area2D2
@onready var inimigo: CharacterBody2D = null
@onready var invecible_time: Timer = $timers/invecible_time
@onready var coyote_timer: Timer = $timers/coyote_timer
@onready var combo_timer: Timer = $timers/combo_timer
@onready var attack_timer: Timer = $timers/attack_timer
@onready var camera : Camera2D = null
@onready var hitbox: Area2D = $hitbox
@onready var leftwall_detector: RayCast2D = $leftwall_detector
@onready var rightwall_detector: RayCast2D = $rightwall_detector



enum PlayerState{
	idle,
	jump,
	falling,
	walking,
	dash,
	attack1,
	wall,
	dead
}


@export_category("Jump variable")
@export var jump_velocity = 300.0
@export var jump_amount = 1
@export var gravity_up = 800.0
@export var gravity_down = 1000.0 
var jump_count = 0

@export_category("Speed variable")
@export var MAX_SPEED = 60.0
@export var acceleration_player = 400
@export var deceleration_player = 400
@export var wall_acceleration = 200
@export var wall_jump_velocity = 400

@export_category("Status player")
@export var Health = 3

var flipped = false
var can_combo = false
var posicao_sprite_blade
var doDash = false
var dashDirection : int
var dashCounter = 0
var dashLimit = 1
var cooldown = false
var knockback_attack = 80.0
var pogo_modifier = 1.2
var is_invincible = false
var coyote_time_activated = false
var status: PlayerState
var knockback_strenght = Vector2(-50.0, -180.0)
var is_attacking
var scale_slash
var attacks = 2
var direction

func _ready() -> void:
	go_to_idle_state()
	area_2d.get_node("CollisionShape2D").set_deferred("disabled", true)
	area_2d_2.get_node("CollisionShape2D").set_deferred("disabled", true)
	area_2d.modulate = Color.html("#FF0000")
	area_2d_2.modulate = Color.html("#FF0000")
	blade_sprite.visible = false
	scale_slash = blade_sprite.scale.x
	print(scale_slash)
	posicao_sprite_blade = blade_sprite.global_position
	var nodes = get_tree().get_nodes_in_group("Camera")
	if nodes.size() == 0:
		return
	camera = nodes[0]

func _physics_process(delta: float) -> void:
	#print(status)
	if not is_on_floor():
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
		PlayerState.attack1:
			attack1_state(delta)
		PlayerState.wall:
			wall_state(delta)
		PlayerState.dead:
			dead_state(delta)

func go_to_dead_state():
	PlayerState.dead
	#anim_player.play("dead", 1.0, false)
	velocity.x = 0
	await get_tree().create_timer(2).timeout
	get_tree().reload_current_scene()

func go_to_idle_state():
	status = PlayerState.idle
	anim_player.play("Idle", -1, 2.0)
	
func go_to_walking_state():
	status = PlayerState.walking
	anim_player.play("Walking", -1, 2.0)
	
func go_to_jump_state():
	status = PlayerState.jump
	anim_player.play("Idle", -1, 2.0)
	
func go_to_falling_state():
	status = PlayerState.falling
	anim_player.play("Falling", -1, 2.0)
	
func go_to_dash_state():
	status = PlayerState.dash
	anim_player.play("Idle", -1, 2.0)
	
func go_to_attack1_state():
	status = PlayerState.attack1
	#anim_player.play("Attacking")
	
func go_to_wall_state():
	status = PlayerState.wall
	anim_player.play("Attacking3")
	velocity = Vector2.ZERO

func dead_state(delta):
	apply_gravity(delta)
	pass
	
func idle_state(delta):
	apply_gravity(delta)
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
		go_to_attack1_state()
		return
	if Input.is_action_just_pressed("dash"):
		go_to_dash_state()
		return

func walking_state(delta):
	apply_gravity(delta)
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
		go_to_attack1_state()
		return
	if Input.is_action_just_pressed("dash"):
		go_to_dash_state()
		return

func jump_state(delta):
	apply_gravity(delta)
	andar(delta)
	jump_logic()
	dash()
	attack()
	if Input.is_action_just_pressed("attack"):
		go_to_attack1_state()
		return
	if Input.is_action_just_pressed("dash"):
		go_to_dash_state()
		return
	if velocity.y > 0:
		go_to_falling_state()
		return

func falling_state(delta):
	apply_gravity(delta)
	andar(delta)
	dash()
	jump_logic()
	attack()
	if Input.is_action_just_pressed("attack"):
		go_to_attack1_state()
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
	if Input.is_action_just_pressed("dash"):
		go_to_dash_state()
	if (leftwall_detector.is_colliding() or rightwall_detector.is_colliding()) && is_on_wall():
		go_to_wall_state()
		return

func dash_state(delta):
	apply_gravity(delta)
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

func attack1_state(delta):
	is_attacking = true
	apply_gravity(delta)
	andar(delta)
	dash()
	attack()
	jump_logic()
	#print(is_attacking)
	if anim_player.is_playing() && anim_player.current_animation == "Attacking":
		is_attacking = false
		await anim_player.animation_finished
	if !is_attacking:
		area_2d.get_node("CollisionShape2D").set_deferred("disabled", true)
		area_2d_2.get_node("CollisionShape2D").set_deferred("disabled", true)
		area_2d.modulate = Color.html("#FF0000")
		area_2d_2.modulate = Color.html("#FF0000")
		blade_sprite.visible = false
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

func wall_state(delta):
	velocity.y += wall_acceleration*delta
	if is_on_floor():
		go_to_idle_state()
		return
	if leftwall_detector.is_colliding():
		cuckold_knight.flip_h = false
		direction = 1
	elif rightwall_detector.is_colliding():
		cuckold_knight.flip_h = true
		direction = -1
	else:
		go_to_falling_state()
		return
	if Input.is_action_just_pressed("jump"):
		do_jump()
		velocity.x += wall_jump_velocity*direction
		go_to_jump_state()
		return

func efeito_dash():
	var playerCopyNode = cuckold_knight.duplicate()
	get_parent().add_child(playerCopyNode)
	playerCopyNode.global_position = Vector2(global_position.x +2, global_position.y - 2)
	playerCopyNode.modulate = Color.html("#4b92fe")
	var tween = create_tween()
	tween.tween_property(playerCopyNode, "modulate:a", 0.0, 0.3)
	tween.tween_callback(Callable(playerCopyNode, "queue_free"))

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
			area_2d_2.get_node("CollisionShape2D").set_deferred("disabled", false)
			area_2d_2.modulate = Color.html("#FF0000")
			blade_sprite.visible = true
			anim_player.play("Attacking", -1, 2.0)
			anim_blade.play("Attacking", -1, 2.0)
			if Input.is_action_pressed("up"):
				if flipped:
					blade_sprite.global_rotation_degrees = +90
					blade_sprite.global_position = Vector2(global_position.x - 2, global_position.y - 16)
				else:
					blade_sprite.global_rotation_degrees = -90
					blade_sprite.global_position = Vector2(global_position.x + 2, global_position.y - 16)
				area_2d_2.global_position = Vector2(global_position.x, global_position.y - 19)
			else:
				if flipped:
					blade_sprite.global_rotation_degrees = -90
					blade_sprite.global_position = Vector2(global_position.x + 2, global_position.y + 16)
				else:
					blade_sprite.global_rotation_degrees = 90
					blade_sprite.global_position = Vector2(global_position.x - 2, global_position.y + 16)
				area_2d_2.global_position = Vector2(global_position.x, global_position.y + 19)
		else:
			combo_timer.start()
			can_combo = true
			blade_sprite.rotation_degrees = 0
			anim_player.play("Attacking", -1, 2.0)
			anim_blade.play("Attacking", -1, 2.0)
			blade_sprite.visible = true
			area_2d.get_node("CollisionShape2D").set_deferred("disabled", false)
			area_2d.modulate = Color.html("#FF0000")
			if flipped:
				area_2d.global_position = Vector2(global_position.x - 13.0, global_position.y)
				blade_sprite.global_position = Vector2(global_position.x - 10, global_position.y)
			else:
				area_2d.global_position = Vector2(global_position.x + 13.0, global_position.y)
				blade_sprite.global_position = Vector2(global_position.x + 10, global_position.y)
		
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
		velocity.y *= 0.5
	else:
		return
func do_jump():
	jump_count += 1
	velocity.y = -jump_velocity

func dash():
	if Input.is_action_just_pressed("dash") && dashCounter < dashLimit && !cooldown:
		direction = Input.get_axis("left", "right")
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
	if is_invincible:
		return
	is_invincible = true
	#Health -= 1
	modulate = Color(1, 1, 1, 0.5)
	invecible_time.start()
	velocity.y = 0
	velocity.y += knockback_strenght.y
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
			if flipped:
				dashDirection = -1
			else:
				dashDirection = 1
		velocity.x = dashDirection * MAX_SPEED * 4
		velocity.y = 0
	else:	
		if direction:
				velocity.x = direction*MAX_SPEED
		else:
				velocity.x = move_toward(velocity.x, 0, MAX_SPEED)
	if direction < 0:
		cuckold_knight.flip_h = true
		if !anim_blade.is_playing():
			blade_sprite.scale.x = -scale_slash
		flipped = true
	elif direction > 0:
		cuckold_knight.flip_h = false
		if !anim_blade.is_playing():
			blade_sprite.scale.x = scale_slash
		flipped = false

func apply_gravity(delta):
	if not is_on_floor():
		if velocity.y < 0:
			velocity.y += gravity_up * delta
		else:
			velocity.y += gravity_down * delta
			
#função para freezar o tempo (tomar dano e etc)
func frame_frezee(timeScale, duration): 
	Engine.time_scale = timeScale
	await(get_tree().create_timer(duration * timeScale).timeout)
	Engine.time_scale = 1.0

func _on_invecible_time_timeout() -> void:
	is_invincible = false
	modulate = Color(1, 1, 1, 1)
	
func _on_coyote_timer_timeout() -> void:
	coyote_time_activated = false
func _on_area_2d_area_entered(area: Area2D) -> void:
	if is_in_group("pogo"):
		if !flipped:
			inimigo.knockback("right")
			knockback_player("right")
		else:
			inimigo.knockback("left")
			knockback_player("left")
	if area.get_parent().is_in_group("inimigos"):
		area_2d_2.get_node("CollisionShape2D").set_deferred("disabled", true)
		area_2d_2.modulate = Color.html("#FFFFFF")
		inimigo = area.get_parent()
		inimigo.levar_dano(1)
		if !flipped:
			inimigo.knockback("right")
			knockback_player("right")
		else:
			inimigo.knockback("left")
			knockback_player("left")
		frame_frezee(0.2, 0.1)
		camera.screen_shake(2, 0.2)


func knockback_player(dir: String):
	var duration := 0.1

	var direction
	if dir == "right":
		direction = 1
	elif dir=="left":
		direction = -1

	var tween := create_tween()
	var start_velocity := velocity.x
	var target_velocity = knockback_strenght.x * direction

	tween.tween_property(self, "velocity:x", target_velocity, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "velocity:x", 0.0, 0.01).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _on_area_2d_2_area_entered(area: Area2D) -> void:
	if area.is_in_group("pogo"):
		if not is_on_floor():
			print("pogo no pau")
			pogo()
			frame_frezee(0.2, 0.1)
			camera.screen_shake(2, 0.2)
			return
	if area.get_parent().is_in_group("inimigos"):
		area_2d.get_node("CollisionShape2D").set_deferred("disabled", true)
		area_2d.modulate = Color.html("#FFFFFF")
		inimigo = area.get_parent()
		inimigo.levar_dano(1)
		if not is_on_floor() && Input.is_action_pressed("down"):
			inimigo.knockback("down")
			pogo()
		elif Input.is_action_pressed("up"):
			inimigo.knockback("up")
		frame_frezee(0.2, 0.1)
		camera.screen_shake(2, 0.2)

func pogo():
	velocity.y = 0
	var tween = create_tween()
	var velocity_inicial = -jump_velocity * pogo_modifier
	var apex_velocity = velocity_inicial * 0.2
	tween.tween_property(self, "velocity:y", velocity_inicial, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "velocity:y", apex_velocity, 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
		if anim_player.current_animation == "Attacking":
			blade_sprite.visible = false
			area_2d.get_node("CollisionShape2D").set_deferred("disabled", false)
			area_2d_2.get_node("CollisionShape2D").set_deferred("disabled", false)

func _on_combo_timer_timeout() -> void:
	can_combo = false
	attacks = 2
	print("cabo o tempo do combo")


func _on_attack_timer_timeout() -> void:
	pass
