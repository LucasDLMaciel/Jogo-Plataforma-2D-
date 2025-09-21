extends CharacterBody2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var dash_duration: Timer = $dash_duration
@onready var dash_effect: Timer = $dash_Effect
@onready var dash_cooldown: Timer = $dash_cooldown
@onready var area_2d: Area2D = $Area2D
@onready var area_2d_2: Area2D = $Area2D2
@onready var inimigo: CharacterBody2D = null


@export_category("Jump variable")
@export var jump_speed = 400.0
@export var acceleration = 590.0
@export var jump_amount = 0

var SPEED = 80.0
var doDash = false
var dashDirection : int
var dashCounter = 0
var dashLimit = 1
var cooldown = false
var knockback = 100.0

func _ready() -> void:
	area_2d.monitoring = false
	area_2d_2.monitoring = false

func _physics_process(delta: float) -> void:
	velocity += get_gravity() * delta
	
	if Input.is_action_just_pressed("attack") && (anim.is_playing() && anim.animation != "get up"):
		if (Input.is_action_pressed("up") or Input.is_action_pressed("down")):
			area_2d_2.monitoring = true
			anim.play("attack", 2.8, false)
			if Input.is_action_pressed("up"):
				area_2d_2.global_position = Vector2(global_position.x, global_position.y - 15.0)
			else:
				area_2d_2.global_position = Vector2(global_position.x, global_position.y + 15.0)
		else: 
			area_2d.monitoring = true
			anim.play("attack", 2.8, false)
			if anim.is_flipped_h():
				area_2d.global_position = Vector2(global_position.x - 12.0, global_position.y)
			else:
				area_2d.global_position = Vector2(global_position.x + 12.0, global_position.y)
	var direction := Input.get_axis("left", "right")
	if anim.animation != "attack" or (not anim.is_playing() and anim.animation == "attack"):
		jump_logic()
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if	Input.is_action_just_pressed("dash") && dashCounter < dashLimit && !cooldown && anim.animation != "attack" && anim.animation == "idle":
		anim.play("get up", 2, false)
		area_2d.monitoring = false
		area_2d_2.monitoring = false
		dash(direction)
	elif anim.animation != "attack" or (not anim.is_playing() and anim.animation == "attack"): 
			andar(direction)
	if is_on_floor():
		if dashCounter == 1 && !cooldown:
			dashCounter = 0
			cooldown = false
		if direction > 0:
			#anim.play("walk")
			anim.set_flip_h(false)
		else: 
			if direction < 0: 
				#anim.play("walk")
				anim.set_flip_h(true)
	if not is_on_floor():
		if direction > 0:
				#anim.play("walk")
			anim.set_flip_h(false)
		else: 
			if direction < 0: 
					#anim.play("walk")
				anim.set_flip_h(true)
	
	move_and_slide()
	
	
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

func jump_logic():
	if is_on_floor():
		jump_amount = 1
		if Input.is_action_just_pressed("jump"):
			jump_amount -= 1
			velocity.y -= lerp(jump_speed, acceleration, 0.2)
	if not is_on_floor():
		if Input.is_action_just_released("jump"):
			velocity.y = lerp(velocity.y, get_gravity().y, 0.2)
			velocity.y *= 0.3
	else:
		return
	#if Input.is_action_pressed("jump") and not is_on_floor() and JUMP_VELOCITY > -300:
		#velocity.y = JUMP_VELOCITY
	
func dash(direction):
	area_2d.monitoring = false
	area_2d_2.monitoring = false
	print("dash usado")
	dashCounter = 1
	dashDirection = direction
	if dashDirection > 0:
		anim.set_flip_h(false)
	else: 
		if dashDirection < 0 :
			anim.set_flip_h(true)
		else:
			anim.set_flip_h(anim.is_flipped_h())			
	doDash = true
	cooldown = true
	dash_duration.start()
	dash_effect.start()
	dash_cooldown.start()
	
		
func andar(direction):
	if doDash:
		if dashDirection == 0 :
			if anim.is_flipped_h():
				dashDirection = -1
			else:
				dashDirection = 1
		velocity.x = dashDirection * SPEED * 3
		velocity.y = 0
	else:	
		if direction:
			if (not anim.is_playing() and anim.animation == "attack") or anim.animation != "attack":
				area_2d.monitoring = false
				area_2d_2.monitoring = false
				anim.play("idle")
			velocity.x = direction * SPEED
		else:
			if (not anim.is_playing() and anim.animation == "attack") or anim.animation != "attack":
				area_2d.monitoring = false
				area_2d_2.monitoring = false
				anim.play("idle", 1.0, false)
			velocity.x = move_toward(velocity.x, 0, SPEED)

func _on_area_2d_body_entered(body: Node2D) -> void:
	area_2d_2.monitoring = false
	if body.is_in_group("inimigos"):
		body == inimigo
		body.health -= 1
		if !anim.is_flipped_h():
			velocity.x -= lerp(SPEED, knockback, 0.1)
			body.knockback("right")
		else:
			velocity.x += lerp(SPEED, knockback, 0.1)
			body.knockback("left")
		if body.health == 0:
			body.queue_free()


func _on_area_2d_2_body_entered(body: Node2D) -> void:
	area_2d.monitoring = false
	if body.is_in_group("inimigos"):
		body == inimigo
		body.health -= 1
		if not is_on_floor() && Input.is_action_pressed("down"):
			body.knockback("down")
			velocity.y -= lerp(jump_speed, acceleration, 0.3)
		elif Input.is_action_pressed("up"):
			body.knockback("up")
			if not is_on_floor():
				velocity.y = lerp(velocity.y, get_gravity().y, 0.3)
				velocity.y *= 0.3
		if body.health == 0:
			body.queue_free()
