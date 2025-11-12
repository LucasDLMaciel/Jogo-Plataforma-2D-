extends CharacterBody2D

@onready var sprite = $SpriteMorcego
@onready var hitbox: Area2D = $hitbox
@onready var explosion: Node2D = $Explosion


const SPEED = 300.0
const FLAP_STRENGTH = -90
const JUMP_VELOCITY = -400.0
const MAX_FALL_SPEED = 400.0      # Limit fall speed so it doesn't fall too fast
const GRAVITY_SCALE = 0.4
var TARGET_ALTITUDE: float  # The Y position it tries to hover around
const ALT_TOLERANCE = 10.0     # How far it can drift before correcting

const WANDER_SPEED = 30.0          # pixels per second
const WANDER_INTERVAL = 1.5        # seconds between direction changes

var wander_dir := -1              # 1 = right, -1 = left
var wander_timer := 0.0
var flip_dir := false

@export var dead = false
@export var health: int = 3

var knockback_vector: Vector2 = Vector2.ZERO
var knockback_strength = 180

var direcao_dash = 0
const DASH_SPEED = 65.0

const PREPARE_SPEED = 5.0

@onready var cooldown_timer: Timer = $CooldownTimer
@onready var dash_timer: Timer = $DashTimer
@onready var prepare_timer: Timer = $PrepareTimer

var status: MorcegoState

enum MorcegoState{
	FLY,
	DEAD,
	PREPARE,
	DASH,
	COOLDOWN
}

const KNOCKBACK_DIRECTIONS = {
	"up": Vector2(0, -1),
	"down": Vector2(0, 1),
	"left": Vector2(-1, 0),
	"right": Vector2(1, 0)
}

func _ready() -> void:
	TARGET_ALTITUDE = global_position.y
	go_to_fly_state()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if dead:
		velocity = get_gravity() * delta * 2
	
	knockback_vector = knockback_vector.move_toward(Vector2.ZERO, 500 * delta)
		
	match status:
		MorcegoState.FLY:
			fly_state(delta)
		MorcegoState.DEAD:
			dead_state(delta)
		MorcegoState.PREPARE:
			prepare_state(delta)
		MorcegoState.DASH:
			dash_state(delta)
		MorcegoState.COOLDOWN:
			cooldown_state(delta)
	
	move_and_slide()

func levar_dano(dano: int):
	health -= dano
	if health <= 0:
		go_to_dead_state()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.levar_dano()
		print("Inimigo atingiu o jogador")

func knockback(comando: StringName):
	if comando in KNOCKBACK_DIRECTIONS:
		knockback_vector = KNOCKBACK_DIRECTIONS[comando] * knockback_strength
		print("Knockback:", comando)

func go_to_fly_state():
	status = MorcegoState.FLY

func fly_state(delta):
	velocity += get_gravity() * GRAVITY_SCALE * delta
	
	if velocity.y > MAX_FALL_SPEED:
		velocity.y = MAX_FALL_SPEED
	
	if global_position.y > TARGET_ALTITUDE + ALT_TOLERANCE:
		velocity.y = FLAP_STRENGTH
		sprite.play("voando", 2.0)
		if flip_dir:
			wander_dir = -wander_dir  # flip direction
			sprite.flip_h = !sprite.flip_h
			flip_dir = false
			
	wander_timer -= delta
	if wander_timer <= 0.0:
		wander_timer = WANDER_INTERVAL
		flip_dir = true

	velocity.x = wander_dir * WANDER_SPEED

func go_to_dead_state():
	status = MorcegoState.DEAD
	sprite.stop()
	velocity = Vector2.ZERO
	dead = true
	await(get_tree().create_timer(0.2).timeout)
	hitbox.process_mode = Node.PROCESS_MODE_DISABLED

func dead_state(_delta):
	await get_tree().create_timer(2).timeout
	modulate.a -= 0.025
	if modulate.a <= 0:
		queue_free()
		print("morcego desapareceu")

func go_to_dash_state():
	status = MorcegoState.DASH
		
	velocity.x = direcao_dash * DASH_SPEED
	velocity.y = 0
	dash_timer.start()
	
func dash_state(_delta):
	move_and_slide()
	
func _on_dash_timer_timeout() -> void:
	if status == MorcegoState.DASH:
		go_to_cooldown_state()

func go_to_cooldown_state():
	status = MorcegoState.COOLDOWN
	velocity = Vector2.ZERO
	cooldown_timer.start()
	
func cooldown_state(_delta):
	move_and_slide()
	
func _on_cooldown_timer_timeout() -> void:
	if status == MorcegoState.COOLDOWN:
		status = MorcegoState.FLY
		$DetectLeft.monitoring = true
		$DetectRight.monitoring = true

func _on_detect_left_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and status == MorcegoState.FLY:
		var dir = -1
		go_to_prepare_state(dir)

func _on_detect_right_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and status == MorcegoState.FLY:
		var dir = 1
		go_to_prepare_state(dir)

func go_to_prepare_state(direcao: int):
	status = MorcegoState.PREPARE
	direcao_dash = direcao
	
	
	$DetectLeft.set_deferred("monitoring", false)
	$DetectRight.set_deferred("monitoring", false)
	
	wander_dir = direcao
	if direcao == 1:
		sprite.flip_h = true
	elif direcao == -1:
		sprite.flip_h = false
	
	velocity.x = PREPARE_SPEED * (-direcao_dash)
	velocity.y = 0
	
	prepare_timer.start()

func prepare_state(_delta):
	move_and_slide()

func _on_prepare_timer_timeout() -> void:
	if status == MorcegoState.PREPARE:
		go_to_dash_state()

func anim_tapa(directionExp : Vector2) -> void:
	explosion.get_children()[0].color = Color.html("#4526a1")
	if health == 0:
		directionExp = Vector2(0,0)
	if directionExp.x == -1:
		explosion.global_position = Vector2(global_position.x - 10, global_position.y)
	elif directionExp.x == +1:
		explosion.global_position = Vector2(global_position.x + 10, global_position.y)
	elif directionExp.y == +1:
		explosion.global_position = Vector2(global_position.x, global_position.y+15)
	elif directionExp.y == -1:
		explosion.global_position = Vector2(global_position.x, global_position.y-15)	
	explosion.anim_tapa(directionExp)
