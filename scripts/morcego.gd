extends CharacterBody2D

@onready var sprite = $SpriteMorcego
@onready var hitbox: Area2D = $hitbox

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

var status: MorcegoState

enum MorcegoState{
	fly,
	dead	
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
		MorcegoState.fly:
			fly_state(delta)
		MorcegoState.dead:
			dead_state(delta)
	
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
	status = MorcegoState.fly

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
	status = MorcegoState.dead
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
